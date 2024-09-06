import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:geotypes/geotypes.dart' as geojson;
import 'package:logging/logging.dart';
import 'dart:convert'; // Import required for jsonEncode

class ParcelMapScreen extends StatefulWidget {
  const ParcelMapScreen({super.key});

  @override
  ParcelMapScreenState createState() => ParcelMapScreenState();
}

class ParcelMapScreenState extends State<ParcelMapScreen> {
  late MapboxMap _mapboxMap;
  geo.Position? _currentPosition;
  String _selectedParcelCode = '';
  final log = Logger('ParcelMapScreen');

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Initialize Map
  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    // Cargar el estilo del mapa a vista satélite
    _mapboxMap.loadStyleURI(MapboxStyles.SATELLITE);

    // Establecer la posición inicial de la cámara
    _setInitialCameraPosition();
  }

  // Set Initial Camera Position after Map is Created
  void _setInitialCameraPosition() {
    _mapboxMap.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position(
            _currentPosition?.longitude ?? -3.7038,
            _currentPosition?.latitude ?? 40.4168,
          ),
        ),
        zoom: 10.0,
      ),
    );
  }

  // Get Current Location using Geolocator
  void _getCurrentLocation() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled; show error or ask for manual input
      return;
    }

    // Request permission to access location
    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        // Permissions are denied, show manual input fields
        return;
      }
    }

    // If permission is granted, get current location
    if (permission == geo.LocationPermission.whileInUse ||
        permission == geo.LocationPermission.always) {
      geo.Position position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      setState(() {
        _currentPosition = position;
        // Update the map position
        _updateMapLocation(position.latitude, position.longitude);
      });
    }
  }

// Update Map Location
  void _updateMapLocation(double latitude, double longitude) {
    _mapboxMap.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(longitude, latitude), // Using Mapbox Position
        ),
        zoom: 15.0,
        bearing: 0.0,
        pitch: 0.0,
      ),
      MapAnimationOptions(
        duration: 1000,
      ),
    );
    _fetchParcelData(latitude, longitude);
  }

  // Fetch Parcel Data from WFS Service
  Future<void> _fetchParcelData(double latitude, double longitude) async {
    final bbox = _calculateBBox(latitude, longitude, 1000); // 1km radius
    final url =
        'http://ovc.catastro.meh.es/INSPIRE/wfsCP.aspx?service=WFS&version=2.0.0&request=GetFeature&typeNames=CP:CadastralParcel&srsName=EPSG:25830&bbox=$bbox';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final xmlDocument = XmlDocument.parse(response.body);
        _parseAndDrawParcels(xmlDocument);
      } else {
        log.warning(
            'Failed to load parcel data: Status code ${response.statusCode}');
      }
    } catch (e) {
      log.severe('Error fetching parcel data', e);
    }
  }

  // Calculate BBOX for WFS Request
  String _calculateBBox(double lat, double lon, double radius) {
    // Calculations for bbox (Example)
    return '$lon,$lat,${lon + 0.01},${lat + 0.01}';
  }

  void _parseAndDrawParcels(XmlDocument xml) {
    // Obtain all XML plot elements
    final List<XmlElement> parcelElements =
        xml.findAllElements('gml:featureMember').toList();

    // Create a data source for Mapbox from plot data
    _mapboxMap.style.addSource(
      GeoJsonSource(
        id: 'source-id',
        data: jsonEncode({
          // Convert the MAP to String
          'type': 'FeatureCollection',
          'features': parcelElements.map((parcel) {
            // Get the coordinates of the plot
            final String coordinatesString =
                parcel.findElements('gml:coordinates').first.value ??
                    ''; // Use `.value` and handle nullability

            final List<String> coordinates =
                coordinatesString.split(' '); // Remove unnecessary nullability

            // Convert coordinates into a format compatible with GeoJSON
            final List<List<double>> geometryCoordinates =
                coordinates.map((coord) {
              final List<String> latLon = coord.split(',');
              return [double.parse(latLon[0]), double.parse(latLon[1])];
            }).toList();

            // Return the GeoJSON object
            return {
              'type': 'Feature',
              'geometry': {
                'type': 'Polygon',
                'coordinates': [geometryCoordinates],
              },
              'properties': {
                'id': parcel.getAttribute('gml:id') ?? 'unknown',
              },
            };
          }).toList(),
        }),
      ),
    );

    // Add the line layer
    _mapboxMap.style.addLayer(
      LineLayer(
        id: 'parcel-lines',
        sourceId: 'source-id',
        lineColor: const Color.fromARGB(255, 244, 67, 54).value,
        lineWidth: 1.0,
      ),
    );
  }

  // Handle Map Click to Select Parcel
  void _onMapClick(MapContentGestureContext clickContext) async {
    // Obtener coordenadas del punto de click en la pantalla
    final screenCoordinate = clickContext.touchPosition;

    // Convertir las coordenadas de pantalla a coordenadas geográficas
    final clickPoint = await _mapboxMap.coordinateForPixel(
      screenCoordinate,
    );

    // Obtener el GeoJsonSource y verificar si existe
    final source = _mapboxMap.style.getSource('source-id') as GeoJsonSource?;
    if (source != null) {
      final data = await source.data;
      final features = jsonDecode(data!)['features'] as List<dynamic>;

      for (final feature in features) {
        final List<dynamic> coordinates = feature['geometry']['coordinates'][0];
        if (_isPointInPolygon(clickPoint, coordinates)) {
          setState(() {
            _selectedParcelCode = feature['properties']['id'];
          });
          log.info('Selected Parcel ID: $_selectedParcelCode');
          break;
        }
      }
    }
  }

  // Helper function to check if a point is inside a polygon
  bool _isPointInPolygon(geojson.Point point, List<dynamic> polygon) {
    final x = point.coordinates[0]; // Access longitude from coordinates array
    final y = point.coordinates[1]; // Access latitude from coordinates array

    if (x == null || y == null) return false; // Check for null values

    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i][0], yi = polygon[i][1];
      final xj = polygon[j][0], yj = polygon[j][1];

      // Check for null values in polygon coordinates
      if (xi == null || yi == null || xj == null || yj == null) continue;

      // Calculate the intersection
      final intersect =
          ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);

      if (intersect) inside = !inside;
    }

    return inside;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcel Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location),
            onPressed: () {
              // Show input fields for latitude and longitude
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MapWidget(
              mapOptions: MapOptions(
                pixelRatio: MediaQuery.of(context).devicePixelRatio,
              ),
              onMapCreated: (MapboxMap mapboxMap) {
                _mapboxMap = mapboxMap;
                _onMapCreated(mapboxMap); // Llamar a la inicialización del mapa
              },
              onTapListener: _onMapClick,
            ),
          ),
          if (_selectedParcelCode.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Text('Selected Parcel Code: $_selectedParcelCode'),
            ),
        ],
      ),
    );
  }
}
