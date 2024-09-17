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
import 'package:geobase/projections_proj4d.dart'; // Import for EPSG:25830 projections
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
      // Request location permissions
      status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        // Permission granted, get current location
        _getCurrentLocation();
      } else {
        log.severe('Location permission denied.');
      }
    } else if (status.isGranted) {
      // Permission already granted, get current location
      _getCurrentLocation();
    } else if (status.isPermanentlyDenied) {
      log.severe(
          'Location permission permanently denied. You need to enable it manually in settings.');
    }
  }

  // Initialize Map
  void _onMapCreated(mapbox.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    // Load satellite view map style
    _mapboxMap.loadStyleURI(mapbox.MapboxStyles.SATELLITE);

    // Set the initial camera position
    _setInitialCameraPosition();
  }

  // Set Initial Camera Position after Map is Created
  void _setInitialCameraPosition() {
    _mapboxMap.setCamera(
      mapbox.CameraOptions(
        center: mapbox.Point(
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
          coordinates: geojson.Position(longitude, latitude),
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
          '+proj=utm +zone=30 +ellps=GRS80 +units=m +no_defs', // EPSG:25830
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

  // Parse and Draw Parcels, but only show information on interaction
  void _parseAndDrawParcels(XmlDocument xml) {
    // Obtener todos los elementos de parcela usando <member>
    final List<XmlElement> parcelElements =
        xml.findAllElements('member').toList();

    // Crear una instancia de proyección para convertir de EPSG:25830 (UTM Zona 30N) a WGS84
    final adapter = Proj4d.init(
      CoordRefSys.normalized(
          'EPSG:25830'), // Sistema de coordenadas de origen (UTM)
      CoordRefSys.CRS84, // Sistema de coordenadas de destino (WGS84)
      sourceDef:
          '+proj=utm +zone=30 +ellps=GRS80 +units=m +no_defs', // EPSG:25830
      targetDef: '+proj=longlat +datum=WGS84 +no_defs', // EPSG:4326
    );

    // Crear datos GeoJSON
    final geoJsonData = jsonEncode({
      'type': 'FeatureCollection',
      'features': parcelElements.map((parcel) {
        // Obtener las coordenadas de la parcela
        final String coordinatesString =
            parcel.findAllElements('gml:posList').first.innerText;

        final List<String> coordinates = coordinatesString.split(' ');

        // Convertir coordenadas al formato GeoJSON
        final List<List<double>> geometryCoordinates = [];
        for (var i = 0; i < coordinates.length; i += 2) {
          final double x = double.parse(coordinates[i]);
          final double y = double.parse(coordinates[i + 1]);

          // Crear un objeto Point con las coordenadas UTM
          final pointUTM = Projected(x: x, y: y);

          try {
            // Convertir las coordenadas UTM Zona 30N a WGS84
            final Geographic pointWGS84 = pointUTM.project(adapter.forward);
            geometryCoordinates.add([pointWGS84.lon, pointWGS84.lat]);
          } catch (e) {
            log.severe('Error al convertir UTM Zona 30N a WGS84: $e');
          }
        }

        // Extraer la referencia catastral y el valor de área del XML
        final String cadastralReference = parcel
            .findAllElements('cp:nationalCadastralReference')
            .first
            .innerText;
        final String areaValue =
            parcel.findAllElements('cp:areaValue').first.innerText;

        // Calcular el centroide de la parcela para el etiquetado
        final centroid = _calculateCentroid(geometryCoordinates);

        // Retornar el objeto GeoJSON
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
            'cadastralReference': cadastralReference,
            'areaValue': areaValue,
            'centroid': centroid,
          },
        };
      }).toList(),
    });

    // Depuración: Imprimir los datos GeoJSON
    print('Generated GeoJSON: $geoJsonData');

    // Crear una instancia de GeoJsonSource usando los datos GeoJSON
    final geoJsonSource = mapbox.GeoJsonSource(
      id: 'source-id',
      data: geoJsonData,
    );

    // Añadir la fuente al mapa
    _mapboxMap.style.addSource(geoJsonSource);

    // Añadir la capa de líneas para dibujar los límites de las parcelas
    _mapboxMap.style.addLayer(
      mapbox.LineLayer(
        id: 'parcel-lines',
        sourceId: 'source-id',
        lineColor: const Color.fromARGB(255, 244, 67, 54).value,
        lineWidth: 1.0,
      ),
    );

    // Añadir capa de símbolos para mostrar etiquetas de texto
    _mapboxMap.style.addLayer(
      mapbox.SymbolLayer(
        id: 'parcel-labels',
        sourceId: 'source-id',
        textFieldExpression: [
          'format',
          ['get', 'cadastralReference'],
          '\n',
          ['get', 'areaValue'],
          ' m²',
        ],
        textSize: 12.0,
        textOffset: [0, 1],
        textAnchor: mapbox.TextAnchor.CENTER,
        textColor: Colors.white.value,
        textHaloColor: Colors.black.value,
        textHaloWidth: 1.5,
      ),
    );

    // Añadir capa de línea para resaltar la parcela seleccionada
    _mapboxMap.style.addLayer(
      mapbox.LineLayer(
        id: 'selected-parcel-line',
        sourceId: 'source-id',
        lineColor: const Color.fromARGB(255, 0, 255, 0).value, // Color verde
        lineWidth: 2.0,
        filter: [
          '==',
          'id',
          _selectedParcelCode,
        ], // Inicialmente, _selectedParcelCode está vacío
      ),
    );
  }

// Helper function to calculate the centroid of a polygon
  List<double> _calculateCentroid(List<List<double>> coordinates) {
    double centroidX = 0;
    double centroidY = 0;
    int numPoints = coordinates.length;

    for (var coordinate in coordinates) {
      centroidX += coordinate[0];
      centroidY += coordinate[1];
    }

    return [centroidX / numPoints, centroidY / numPoints];
  }

  // Handle Map Click to Select Parcel
  void _onMapClick(mapbox.MapContentGestureContext clickContext) async {
    // Obtain coordinates of the click point on the screen
    final screenCoordinate = clickContext.touchPosition;

    // Convert screen coordinates to geographic coordinates
    final clickPoint = await _mapboxMap.coordinateForPixel(
      screenCoordinate,
    );

    // Obtener el GeoJsonSource (no es necesario verificar si es null)
    final sourceFuture = _mapboxMap.style.getSource('source-id');
    final source = await sourceFuture;
    if (source is mapbox.GeoJsonSource) {
      final data = await source.data;

      if (data != null) {
        // Verificar si `data` no es nulo
        final features = jsonDecode(data)['features'] as List<dynamic>;

        for (final feature in features) {
          final List<dynamic> coordinates =
              feature['geometry']['coordinates'][0];
          if (_isPointInPolygon(clickPoint, coordinates)) {
            setState(() {
              _selectedParcelCode = feature['properties']['id'];
              _showParcelInfo(feature['properties']);
            });
            log.info('Selected Parcel ID: $_selectedParcelCode');
            break;
          }
        }
      } else {
        log.warning('El dato del GeoJsonSource es nulo.');
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

  // Show information of the selected parcel in a bottom panel
  void _showParcelInfo(Map<String, dynamic> properties) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Referencia Catastral: ${properties['cadastralReference']}'),
              Text('Área: ${properties['areaValue']} m²'),
            ],
          ),
        );
      },
    );
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
                _onMapCreated(mapboxMap); // Initialize the map
              },
              onTapListener: _onMapClick, // Handle map click
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
