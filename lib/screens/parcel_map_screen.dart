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

    // Load satellite view map style and wait for it to be fully loaded
    _mapboxMap.loadStyleURI(mapbox.MapboxStyles.SATELLITE).then((_) {
      log.info('Mapbox style fully loaded and ready.');
      // Here you can enable the click listener or perform other necessary operations
    }).catchError((e) {
      log.severe('Failed to load style: $e');
    });

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
    // Get all plot elements using <member>
    final List<XmlElement> parcelElements =
        xml.findAllElements('member').toList();

    // Create a projection instance to convert from EPSG:25830 (UTM Zone 30N) to WGS84
    final adapter = Proj4d.init(
      CoordRefSys.normalized('EPSG:25830'), // Source coordinate system (UTM)
      CoordRefSys.CRS84, // Target coordinate system (WGS84)
      sourceDef:
          '+proj=utm +zone=30 +ellps=GRS80 +units=m +no_defs', // EPSG:25830
      targetDef: '+proj=longlat +datum=WGS84 +no_defs', // EPSG:4326
    );

    // Crear datos GeoJSON
    final geoJsonData = jsonEncode({
      'type': 'FeatureCollection',
      'features': parcelElements.map((parcel) {
        // Get the coordinates of the plot
        final String coordinatesString =
            parcel.findAllElements('gml:posList').first.innerText;

        final List<String> coordinates = coordinatesString.split(' ');

        // Convert coordinates to GeoJSON format
        final List<List<double>> geometryCoordinates = [];
        for (var i = 0; i < coordinates.length; i += 2) {
          final double x = double.parse(coordinates[i]);
          final double y = double.parse(coordinates[i + 1]);

          // Create a Point object with UTM coordinates
          final pointUTM = Projected(x: x, y: y);

          try {
            // Convert UTM Zone 30N coordinates to WGS84
            final Geographic pointWGS84 = pointUTM.project(adapter.forward);
            geometryCoordinates.add([pointWGS84.lon, pointWGS84.lat]);
          } catch (e) {
            log.severe('Error converting UTM Zone 30N to WGS84: $e');
          }
        }

        // Extract the cadastral reference and area value from the XML
        final String cadastralReference = parcel
            .findAllElements('cp:nationalCadastralReference')
            .first
            .innerText;
        final String areaValue =
            parcel.findAllElements('cp:areaValue').first.innerText;

        // Calculate the centroid of the plot for labeling
        final centroid = _calculateCentroid(geometryCoordinates);

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
            'cadastralReference': cadastralReference,
            'areaValue': areaValue,
            'centroid': centroid,
          },
        };
      }).toList(),
    });

    // Log the generated GeoJSON data
    log.info('Generated GeoJSON: $geoJsonData');

    // Create a GeoJsonSource instance using GeoJSON data
    final geoJsonSource = mapbox.GeoJsonSource(
      id: 'source-id',
      data: geoJsonData,
    );

    // Add source to map
    _mapboxMap.style.addSource(geoJsonSource);

    // Add the line layer to draw the boundaries of the parcels
    _mapboxMap.style.addLayer(
      mapbox.LineLayer(
        id: 'parcel-lines',
        sourceId: 'source-id',
        lineColor: const Color.fromARGB(255, 244, 67, 54).value,
        lineWidth: 1.0,
      ),
    );

    // Add symbol layer to display text labels
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

    // Add line layer to highlight the selected plot
    _mapboxMap.style.addLayer(
      mapbox.LineLayer(
        id: 'selected-parcel-line',
        sourceId: 'source-id',
        lineColor: const Color.fromARGB(255, 0, 255, 0).value,
        lineWidth: 2.0,
        filter: [
          '==',
          'id',
          _selectedParcelCode,
        ], // Initially, _selectedParcelCode is empty
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

  // Function to highlight the selected parcel
  void _highlightSelectedParcel(String parcelId) {
    _mapboxMap.style.updateLayer(
      mapbox.LineLayer(
        id: 'selected-parcel-line',
        sourceId: 'source-id',
        lineColor: const Color.fromARGB(150, 0, 255, 0)
            .value, // Green with transparency
        lineWidth: 2.0,
        filter: ['==', 'id', parcelId],
      ),
    );
  }

  // Handle Map Click to Select Parcel
  void _onMapClick(mapbox.MapContentGestureContext clickContext) async {
    final screenCoordinate = clickContext.touchPosition;

    try {
      // Create RenderedQueryGeometry with properly formatted ScreenCoordinate
      final renderedQueryGeometry = mapbox.RenderedQueryGeometry(
        value: jsonEncode([
          screenCoordinate.x,
          screenCoordinate.y,
        ]), // A list of doubles for x and y coordinates
        type: mapbox.Type.SCREEN_COORDINATE,
      );

      // Query rendered features at the clicked point to find the parcel
      final features = await _mapboxMap.queryRenderedFeatures(
        renderedQueryGeometry,
        mapbox.RenderedQueryOptions(
          layerIds: ['parcel-lines', 'parcel-labels'], // Layer IDs to query
        ),
      );

      if (features.isNotEmpty) {
        // Get the first feature (parcel) from the list
        final feature = features.first;

        // Check if feature is not null
        if (feature != null) {
          // Extract the properties of the parcel
          final rawProperties = feature.queriedFeature.feature['properties'];

          // Safely cast the properties map to Map<String, dynamic>
          final properties = Map<String, dynamic>.from(
            rawProperties as Map<Object?, Object?>,
          );

          // Extract specific properties needed
          final cadastralReference = properties['cadastralReference'];
          final areaValue = properties['areaValue'];
          final parcelId = properties['id'];

          if (cadastralReference != null &&
              areaValue != null &&
              parcelId != null) {
            setState(() {
              _selectedParcelCode = parcelId as String;
            });

            // Highlight the selected parcel
            _highlightSelectedParcel(_selectedParcelCode);

            // Show parcel information
            _showParcelInfo({
              'cadastralReference': cadastralReference,
              'areaValue': areaValue,
            });

            log.info(
                'Selected Parcel: $cadastralReference, Area: $areaValue m²');
          } else {
            log.warning('Parcel properties are incomplete.');
          }
        } else {
          log.warning('No valid parcel found at clicked location.');
        }
      } else {
        log.warning('No parcel found at clicked location.');
      }
    } catch (e, stacktrace) {
      log.severe('Error querying features: $e', e, stacktrace);
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
