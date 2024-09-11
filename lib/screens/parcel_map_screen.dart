import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:geotypes/geotypes.dart' as geojson;
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geobase/geobase.dart';
import 'package:geobase/projections_proj4d.dart'; // Additional import for projections such as EPSG:25830
import 'dart:convert'; // Import required for jsonEncode

class ParcelMapScreen extends StatefulWidget {
  const ParcelMapScreen({super.key});

  @override
  ParcelMapScreenState createState() => ParcelMapScreenState();
}

class ParcelMapScreenState extends State<ParcelMapScreen> {
  late mapbox.MapboxMap _mapboxMap;
  geo.Position? _currentPosition;
  String _selectedParcelCode = '';
  final log = Logger('ParcelMapScreen');

  // Retrieve the Mapbox Access Token from environment variables
  final String accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  @override
  void initState() {
    super.initState();
    // Set Mapbox Access Token
    mapbox.MapboxOptions.setAccessToken(accessToken);
    _requestLocationPermission();
  }

  // Function to request location permission
  Future<void> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      // Solicitar permisos de ubicación
      status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        // Permiso concedido, obtener ubicación actual
        _getCurrentLocation();
      } else {
        log.severe('Permiso de ubicación denegado.');
      }
    } else if (status.isGranted) {
      // Permiso ya concedido, obtener ubicación actual
      _getCurrentLocation();
    } else if (status.isPermanentlyDenied) {
      // Permiso permanentemente denegado
      log.severe(
          'Permiso de ubicación permanentemente denegado. Necesitas habilitarlo manualmente en la configuración.');
    }
  }

  // Initialize Map
  void _onMapCreated(mapbox.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    // Cargar el estilo del mapa a vista satélite
    _mapboxMap.loadStyleURI(mapbox.MapboxStyles.SATELLITE);

    // Establecer la posición inicial de la cámara
    _setInitialCameraPosition();
  }

  // Set Initial Camera Position after Map is Created
  void _setInitialCameraPosition() {
    _mapboxMap.setCamera(
      mapbox.CameraOptions(
        center: mapbox.Point(
          // This uses mapbox_maps_flutter Point
          coordinates: geojson.Position(
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
      mapbox.CameraOptions(
        center: mapbox.Point(
          // This uses mapbox_maps_flutter Point
          coordinates:
              geojson.Position(longitude, latitude), // Using Mapbox Position
        ),
        zoom: 15.0,
        bearing: 0.0,
        pitch: 0.0,
      ),
      mapbox.MapAnimationOptions(
        duration: 1000,
      ),
    );
    _fetchParcelData(latitude, longitude);
  }

  // Fetch Parcel Data from WFS Service
  Future<void> _fetchParcelData(double latitude, double longitude) async {
    final bbox = _calculateBBox(latitude, longitude, 500); // 0.5km radius
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
    // Create a projection instance for EPSG:4326 (WGS84) to EPSG:25830 (UTM Zone 30N)
    final adapter = Proj4d.init(
      CoordRefSys.CRS84, // EPSG:4326
      CoordRefSys.normalized('EPSG:25830'), // EPSG:25830
      sourceDef:
          '+proj=longlat +datum=WGS84 +no_defs', // Definition of EPSG:4326
      targetDef:
          '+proj=utm +zone=30 +ellps=GRS80 +units=m +no_defs', // Definition of EPSG:25830
    );

    // Convert a geographic point (lon, lat) to UTM (EPSG:25830)
    final projected = Geographic(lon: lon, lat: lat).project(adapter.forward);
    final x = projected.x;
    final y = projected.y;

    // Define valid limits for EPSG:25830
    const minXLimit = 166021;
    const maxXLimit = 833978;
    const minYLimit = 0;
    const maxYLimit = 9329005;

    // Calculate BBox limits based on radius
    var minX = (x - radius).round();
    var minY = (y - radius).round();
    var maxX = (x + radius).round();
    var maxY = (y + radius).round();

    // Limit the BBox range within the allowed limits
    minX = minX < minXLimit ? minXLimit : minX;
    maxX = maxX > maxXLimit ? maxXLimit : maxX;
    minY = minY < minYLimit ? minYLimit : minY;
    maxY = maxY > maxYLimit ? maxYLimit : maxY;

    // Return the BBox in the expected format
    return '$minX,$minY,$maxX,$maxY';
  }

  void _parseAndDrawParcels(XmlDocument xml) {
    // Obtain all XML plot elements using <member>
    final List<XmlElement> parcelElements =
        xml.findAllElements('member').toList();

    // Create a projection instance to convert from EPSG:25830 (UTM Zone 30N) to WGS84
    final adapter = Proj4d.init(
      CoordRefSys.normalized('EPSG:25830'), // Source coordinates system (UTM)
      CoordRefSys.CRS84, // Target coordinates system (WGS84)
      sourceDef:
          '+proj=utm +zone=30 +ellps=GRS80 +units=m +no_defs', // Definition of EPSG:25830
      targetDef:
          '+proj=longlat +datum=WGS84 +no_defs', // Definition of EPSG:4326
    );

    // Create a data source for Mapbox from plot data
    _mapboxMap.style.addSource(
      mapbox.GeoJsonSource(
        id: 'source-id',
        data: jsonEncode({
          'type': 'FeatureCollection',
          'features': parcelElements.map((parcel) {
            // Get the coordinates of the plot
            final String coordinatesString =
                parcel.findAllElements('gml:posList').first.innerText;

            final List<String> coordinates = coordinatesString
                .split(' '); // Divide the coordinates into a list

            // Temporarily hardcoding coordinates for testing conversion
            // final List<String> coordinates = ['656153', '4213101'];

            // Convert coordinates to a format that can be used in GeoJSON
            final List<List<double>> geometryCoordinates = [];
            for (var i = 0; i < coordinates.length; i += 2) {
              final double x = double.parse(coordinates[i]);
              final double y = double.parse(coordinates[i + 1]);

              // Create a Point object with the UTM coordinates
              final pointUTM = Projected(x: x, y: y);

              try {
                // Convert the UTM Zone 30N coordinates to WGS84
                final Geographic pointWGS84 = pointUTM.project(adapter.forward);

                geometryCoordinates.add([pointWGS84.lon, pointWGS84.lat]);
              } catch (e) {
                log.severe('Error converting UTM Zone 30N to WGS84: $e');
              }
            }

            // Return the GeoJSON object
            return {
              'type': 'Feature',
              'geometry': {
                'type': 'Polygon',
                'coordinates': [geometryCoordinates],
              },
              'properties': {
                'id': parcel
                        .findAllElements('cp:CadastralParcel')
                        .first
                        .getAttribute('gml:id') ??
                    'unknown',
              },
            };
          }).toList(),
        }),
      ),
    );

    // Add the line layer
    _mapboxMap.style.addLayer(
      mapbox.LineLayer(
        id: 'parcel-lines',
        sourceId: 'source-id',
        lineColor: const Color.fromARGB(255, 244, 67, 54).value,
        lineWidth: 1.0,
      ),
    );
  }

  // Handle Map Click to Select Parcel
  void _onMapClick(mapbox.MapContentGestureContext clickContext) async {
    // Obtener coordenadas del punto de click en la pantalla
    final screenCoordinate = clickContext.touchPosition;

    // Convertir las coordenadas de pantalla a coordenadas geográficas
    final clickPoint = await _mapboxMap.coordinateForPixel(
      screenCoordinate,
    );

    // Obtener el GeoJsonSource y verificar si existe
    final source =
        _mapboxMap.style.getSource('source-id') as mapbox.GeoJsonSource?;
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
            child: mapbox.MapWidget(
              mapOptions: mapbox.MapOptions(
                pixelRatio: MediaQuery.of(context).devicePixelRatio,
              ),
              onMapCreated: (mapbox.MapboxMap mapboxMap) {
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
