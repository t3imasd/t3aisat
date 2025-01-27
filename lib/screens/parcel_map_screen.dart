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
import 'dart:async'; // Import for Timer
import 'package:flutter/services.dart'; // Añade este import para el clipboard
import '../widgets/search_bar_widget.dart'; // The widget of the search bar imports
import '../model/search_result.dart'; // The search results model imports

class ParcelMapScreen extends StatefulWidget {
  const ParcelMapScreen({super.key});

  @override
  ParcelMapScreenState createState() => ParcelMapScreenState();
}

class ParcelMapScreenState extends State<ParcelMapScreen>
    with TickerProviderStateMixin {
  late mapbox.MapboxMap _mapboxMap;
  geo.Position? _currentPosition;
  final List<String> _selectedParcelIds =
      []; // List to hold selected parcel IDs
  final Map<String, String> _selectedParcels =
      {}; // Map to hold cadastral ref and area for selected parcels
  final log = Logger('ParcelMapScreen');
  Timer? _debounce; // Timer to handle user inactivity after scrolling
  bool _isFetching = false;
  bool _isBottomSheetExpanded = false; // Track the state of the bottom sheet

  // Add to class state variables
  bool _isErrorMessageVisible = false;
  final _errorMessageKey = GlobalKey();

  // Retrieve the Mapbox Access Token from environment variables
  final String accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  // Declare the projections as global variables
  late Proj4d epsg25830;
  late Proj4d epsg4326;

  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _spinnerAnimationController;
  late Animation<double> _spinnerAnimation;

  // Add this variable to hold the timer
  Timer? _locationUpdateTimer;

  StreamSubscription<geo.Position>? _positionStreamSubscription;

  final List<geo.Position> _positionHistory = [];

  // Add new state variables
  bool _isSearchBarVisible = false;
  Timer? _searchBarTimer;
  bool _isSearchBarActive = false; // Add this new state variable

  late AnimationController _searchBarAnimationController;
  late Animation<double> _searchBarOpacity;

  // Add new state variable
  bool _isBottomSheetVisible = true;

  @override
  void initState() {
    super.initState();
    // Register the projections once
    _registerProjections();

    // Set Mapbox Access Token
    mapbox.MapboxOptions.setAccessToken(accessToken);
    _requestLocationPermission();

    // Initialize animation controller for pulsating effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 12.0, end: 24.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Initialize spinner animation controller
    _spinnerAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _spinnerAnimation = CurvedAnimation(
      parent: _spinnerAnimationController,
      curve: Curves.easeInOut,
    );

    // Set up a timer to update the user's location every 30 seconds
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 30), (Timer timer) {
      _updateUserLocation();
    });

    _startLocationUpdates();

    _searchBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchBarOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchBarAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _locationUpdateTimer?.cancel();

    _spinnerAnimationController.dispose();
    _animationController.dispose();
    _positionStreamSubscription?.cancel();
    _searchBarTimer?.cancel(); // Add this line
    _searchBarAnimationController.dispose();
    super.dispose();
  }

// Function to register the projections only once
  void _registerProjections() {
    // EPSG:4326 (WGS84) to EPSG:25830 (UTM Zone 30N)
    epsg25830 = Proj4d.init(
      CoordRefSys.CRS84, // EPSG:4326
      CoordRefSys.normalized('EPSG:25830'), // EPSG:25830
      sourceDef: '+proj=longlat +datum=WGS84 +no_defs', // EPSG:4326 definition
      targetDef:
          '+proj=utm +zone=30 +ellps=GRS80 +units=m +no_defs', // EPSG:25830 definition
    );

    // EPSG:25830 (UTM Zone 30N) to EPSG:4326 (WGS84)
    epsg4326 = Proj4d.init(
      CoordRefSys.normalized('EPSG:25830'), // EPSG:25830
      CoordRefSys.CRS84, // WGS84
      sourceDef:
          '+proj=utm +zone=30 +ellps=GRS80 +units=m +no_defs', // EPSG:25830 definition
      targetDef: '+proj=longlat +datum=WGS84 +no_defs', // EPSG:4326 definition
    );
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

    // Load satellite style and wait for complete loading
    _mapboxMap.loadStyleURI(mapbox.MapboxStyles.SATELLITE_STREETS).then((_) {
      log.info('Estilo de Mapbox cargado y listo.');

      // Initialize Map and add user location layer after loading
      _addUserLocationLayer();

      // Move map to current location if needed
      _moveToCurrentLocation();

      // Set initial camera position if needed
      _setInitialCameraPosition();

      // Set up listeners if needed
      _mapboxMap.setOnMapMoveListener(_onMapMove);
    }).catchError((e) {
      log.severe('Error al cargar el estilo: $e');
    });
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
          accuracy: geo.LocationAccuracy.best,
        ),
      );
      setState(() {
        _currentPosition = position;
        // Update the map position
        _updateMapLocation(position.latitude, position.longitude);
      });
      _addUserLocationLayer();
    }
  }

  // Update Map Location
  void _updateMapLocation(double latitude, double longitude) {
    _mapboxMap.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: geojson.Position(longitude, latitude),
        ),
        zoom: 18.0,
        bearing: 0.0,
        pitch: 0.0,
      ),
      mapbox.MapAnimationOptions(
        duration: 1000,
      ),
    );
    _fetchParcelData(latitude, longitude);

    setState(() {
      _currentPosition = geo.Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    });
    _addUserLocationLayer();
  }

  // Generate GeoJSON data from XML
  String _generateGeoJsonData(XmlDocument xml) {
    // Get all parcel elements using <member>
    final List<XmlElement> parcelElements =
        xml.findAllElements('member').toList();

    // Reuse registered projection for EPSG:4326
    final adapter = epsg4326;

    // Create GeoJSON data
    final geoJsonData = jsonEncode({
      'type': 'FeatureCollection',
      'features': parcelElements.map((parcel) {
        // Get parcel coordinates
        final String coordinatesString =
            parcel.findAllElements('gml:posList').first.innerText;

        final List<String> coordinates = coordinatesString.split(' ');

        // Convert coordinates to GeoJSON format
        final List<List<double>> geometryCoordinates = [];
        for (var i = 0; i < coordinates.length; i += 2) {
          final double x = double.parse(coordinates[i]);
          final double y = double.parse(coordinates[i + 1]);

          // Create Point object with UTM coordinates
          final pointUTM = Projected(x: x, y: y);

          try {
            // Convert UTM Zone 30N coordinates to WGS84
            final Geographic pointWGS84 = pointUTM.project(adapter.forward);
            geometryCoordinates.add([pointWGS84.lon, pointWGS84.lat]);
          } catch (e) {
            log.severe('Error converting UTM Zone 30N to WGS84: $e');
          }
        }

        // Get cadastral reference and area value from XML
        final String cadastralReference = parcel
            .findAllElements('cp:nationalCadastralReference')
            .first
            .innerText;
        final String areaValue =
            parcel.findAllElements('cp:areaValue').first.innerText;

        // Calculate parcel centroid for labels
        final centroid = _calculateCentroid(geometryCoordinates);

        // Return GeoJSON object
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

    return geoJsonData;
  }

  // Add layers to show the plots
  void _addParcelLayers() {
    // Add line layer to draw parcel boundaries
    _mapboxMap.style.addLayer(
      mapbox.LineLayer(
        id: 'parcel-lines',
        sourceId: 'source-id',
        lineColor: const Color(0xFFD32F2F).value, // Red color for lines
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
          ['get', 'areaValue'],
          ' m²',
        ],
        textSize: 14.0,
        textOffset: [0, 1],
        textAnchor: mapbox.TextAnchor.CENTER,
        textColor: const Color(0xFF000000).value, // Black color for text
        textHaloColor: Colors.white.value,
        textHaloWidth: 1.5,
      ),
    );

    // Add line layer to highlight selected parcel
    _mapboxMap.style.addLayer(
      mapbox.LineLayer(
        id: 'selected-parcel-line',
        sourceId: 'source-id',
        lineColor: const Color(0xFFF57C00).value, // Orange color for highlight
        lineWidth: 2.0,
        filter: [
          'in',
          'id',
          ..._selectedParcelIds, // Spread operator to include all selected IDs
        ],
      ),
    );

    // Add FillLayer to detect clicks inside parcels
    _mapboxMap.style.addLayer(
      mapbox.FillLayer(
        id: 'parcel-fill',
        sourceId: 'source-id',
        fillColor: Colors.transparent.value, // Fill is transparent
        fillOutlineColor:
            const Color(0xFFD32F2F).value, // Same color as lines
      ),
    );
  }

  // Fetch Parcel Data from WFS Service
  Future<void> _fetchParcelData(double latitude, double longitude) async {
    if (_isFetching) return; // Prevent multiple requests at the same time

    setState(() {
      _isFetching = true; // Set flag to true to indicate a request is ongoing
    });

    // Obtain the current state of the camera, including zoom
    mapbox.CameraState cameraState = await _mapboxMap.getCameraState();

    try {
      // Use camera status to calculate the bbox
      final bbox = _calculateBBox(latitude, longitude, cameraState);
      final url =
          'http://ovc.catastro.meh.es/INSPIRE/wfsCP.aspx?service=WFS&version=2.0.0&request=GetFeature&typeNames=CP:CadastralParcel&srsName=EPSG:25830&bbox=$bbox';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (_isValidXmlContent(response.body)) {
          final xmlDocument = XmlDocument.parse(response.body);
          // Continue with existing logic
          // Generate new GeoJSON data
          final newGeoJsonData = _generateGeoJsonData(xmlDocument);

          final isSourceIdExists =
              await _mapboxMap.style.styleSourceExists('source-id');
          if (isSourceIdExists) {
            // If source already exists, update the property 'data' with new data
            await _mapboxMap.style.setStyleSourceProperty(
              'source-id',
              'data',
              newGeoJsonData,
            );
            log.info("Source 'source-id' updated with new parcel data.");
          } else {
            // If source doesn't exist, create it and add necessary layers
            final geoJsonSource = mapbox.GeoJsonSource(
              id: 'source-id',
              data: newGeoJsonData,
            );

            _mapboxMap.style.addSource(geoJsonSource);

            // Add layers again if source did not exist
            _addParcelLayers();
          }

          // Wait briefly to ensure data has rendered
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          _showTemporaryMessage();
        }
      } else {
        log.warning(
            'Failed to load parcel data: Status code ${response.statusCode}');
      }
    } catch (e) {
      log.severe('Error fetching parcel data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetching =
              false; // Reset the flag after all operations are complete
        });
      }
    }
  }

  // Calculate BBOX for WFS Request
  String _calculateBBox(
      double lat, double lon, mapbox.CameraState cameraState) {
    // Get the zoom level from the camera state
    double zoomLevel = cameraState.zoom;

    // Calculate radius based on zoom level
    double radius = _radiusForZoomLevel(zoomLevel);

    // Reuse the registered projection for EPSG:25830
    final projected = Geographic(lon: lon, lat: lat).project(epsg25830.forward);
    double x = projected.x;
    double y = projected.y;

    // EPSG:25830 limits
    const double minXLimit = 166021;
    const double maxXLimit = 833978;
    const double minYLimit = 0;
    const double maxYLimit = 9329005;

    log.info('RAW VALUES');
    log.info((x - radius));
    log.info((x + radius));
    log.info((y - radius));
    log.info((y + radius));

    log.info('CLAMPED VALUES');
    log.info((x - radius).clamp(minXLimit, maxXLimit));
    log.info((x + radius).clamp(minXLimit, maxXLimit));
    log.info((y - radius).clamp(minYLimit, maxYLimit));
    log.info((y + radius).clamp(minYLimit, maxYLimit));

    // Calculate bbox, but limit it to the valid range for EPSG:25830
    int minX = (x - radius).clamp(minXLimit, maxXLimit).round();
    int maxX = (x + radius).clamp(minXLimit, maxXLimit).round();
    int minY = (y - radius).clamp(minYLimit, maxYLimit).round();
    int maxY = (y + radius).clamp(minYLimit, maxYLimit).round();

    log.info('ROUNDED VALUES');
    log.info((x - radius).clamp(minXLimit, maxXLimit).round());
    log.info((x + radius).clamp(minXLimit, maxXLimit).round());
    log.info((y - radius).clamp(minYLimit, maxYLimit).round());
    log.info((y + radius).clamp(minYLimit, maxYLimit).round());

    // Return the BBox in the expected format
    return '$minX,$minY,$maxX,$maxY';
  }

  // Helper function to calculate radius based on zoom level
  double _radiusForZoomLevel(double zoomLevel) {
    // Adjust radius dynamically based on zoom level
    if (zoomLevel > 15) return 100; // 100 meters for high zoom
    if (zoomLevel > 12) return 500; // 500 meters for medium zoom
    return 100; // 0.1km for lower zoom
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

  // Highlight all selected parcels
  void _highlightSelectedParcels() async {
    // Ensure the style is fully loaded before making changes
    bool isStyleLoaded = await _mapboxMap.style.isStyleLoaded();

    if (!isStyleLoaded) {
      log.warning('Style is not fully loaded yet.');
      return;
    }

    // Verify if the layers already exist
    bool lineLayerExists =
        await _mapboxMap.style.styleLayerExists('selected-parcel-line');
    bool fillLayerExists =
        await _mapboxMap.style.styleLayerExists('selected-parcel-fill');

    // Update if layer exists
    if (lineLayerExists) {
      // Update if there is already
      _mapboxMap.style.updateLayer(
        mapbox.LineLayer(
          id: 'selected-parcel-line',
          sourceId: 'source-id',
          lineColor: const Color(0xFFF57C00).value, // Orange for contour
          lineWidth: 2.0,
          filter: [
            'in',
            'id',
            ..._selectedParcelIds
          ], // Highlight all selected plots
        ),
      );
    } else {
      // Add if layer doesn't exist
      await _mapboxMap.style.addLayer(
        mapbox.LineLayer(
          id: 'selected-parcel-line',
          sourceId: 'source-id',
          lineColor:
              const Color(0xFFF57C00).value, // Color naranja para el contorno
          lineWidth: 2.0,
          filter: [
            'in',
            'id',
            ..._selectedParcelIds
          ], // Highlight all selected plots
        ),
      );
    }

    // Remove fill layer if it exists
    if (fillLayerExists) {
      await _mapboxMap.style.removeStyleLayer('selected-parcel-fill');
    }

    // Add or update fill layer for selected parcels
    await _mapboxMap.style.addLayer(
      mapbox.FillLayer(
        id: 'selected-parcel-fill',
        sourceId: 'source-id',
        fillColor:
            const Color(0xFFF57C00).value, // Orange fill for selected plots
        fillOpacity: 0.3, // Fill opacity
        filter: [
          'in',
          'id',
          ..._selectedParcelIds
        ], // Highlight all selected plots
      ),
    );
  }

  // Calculate total area of selected parcels
  String _calculateTotalArea() {
    double totalArea = 0;
    _selectedParcels.forEach((key, value) {
      final area =
          double.tryParse(value.split('-')[1].replaceAll(' m²', '')) ?? 0;
      totalArea += area;
    });
    return totalArea.toStringAsFixed(0);
  }

  // Handle Map Click to Select/Deselect Parcel
  void _onMapClick(mapbox.MapContentGestureContext clickContext) async {
    final screenCoordinate = clickContext.touchPosition;
    try {
      final renderedQueryGeometry =
          mapbox.RenderedQueryGeometry.fromScreenCoordinate(screenCoordinate);
      final features = await _mapboxMap.queryRenderedFeatures(
        renderedQueryGeometry,
        mapbox.RenderedQueryOptions(
          layerIds: ['parcel-fill', 'parcel-lines', 'parcel-labels'],
        ),
      );

      if (features.isNotEmpty) {
        final feature = features.first;
        Map<String, dynamic> properties = {};
        if (feature != null &&
            feature.queriedFeature.feature['properties'] != null) {
          properties = Map<String, dynamic>.from(
            feature.queriedFeature.feature['properties']
                as Map<Object?, Object?>,
          );
        }

        final cadastralReference = properties['cadastralReference'];
        final areaValue = properties['areaValue'];
        final parcelId = properties['id'];

        if (cadastralReference != null &&
            areaValue != null &&
            parcelId != null) {
          setState(() {
            if (_selectedParcelIds.contains(parcelId)) {
              _selectedParcelIds.remove(parcelId);
              _selectedParcels.remove(parcelId);
            } else {
              _selectedParcelIds.add(parcelId);
              _selectedParcels[parcelId] =
                  '$cadastralReference - $areaValue m²';
            }

            // Optimize layer updates
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 16), () async {
                if (!mounted) return;

                try {
                  // Remove existing layers if they exist
                  if (await _mapboxMap.style
                      .styleLayerExists('selected-parcel-line')) {
                    await _mapboxMap.style
                        .removeStyleLayer('selected-parcel-line');
                  }
                  if (await _mapboxMap.style
                      .styleLayerExists('selected-parcel-fill')) {
                    await _mapboxMap.style
                        .removeStyleLayer('selected-parcel-fill');
                  }

                  // Add new layers immediately after removing previous ones
                  await _mapboxMap.style.addLayer(
                    mapbox.LineLayer(
                      id: 'selected-parcel-line',
                      sourceId: 'source-id',
                      lineColor: const Color(0xFFF57C00).value,
                      lineWidth: 2.0,
                      filter: ['in', 'id', ..._selectedParcelIds],
                    ),
                  );

                  await _mapboxMap.style.addLayer(
                    mapbox.FillLayer(
                      id: 'selected-parcel-fill',
                      sourceId: 'source-id',
                      fillColor: const Color(0xFFF57C00).value,
                      fillOpacity: 0.3,
                      filter: ['in', 'id', ..._selectedParcelIds],
                    ),
                  );
                } catch (e) {
                  log.severe('Error updating layers: $e');
                }
              });
            });
          });
        } else {
          log.warning('Parcel properties are incomplete.');
        }
      } else {
        log.warning('No valid parcel found at clicked location.');
      }
    } catch (e) {
      log.severe('Error querying features: $e');
    }
  }

  // Handle Map Move events
  void _onMapMove(mapbox.MapContentGestureContext context) {
    // Cancel any pending requests while the user is moving the map
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }

    // Wait for 1 second after the last scroll event before fetching new data
    _debounce = Timer(const Duration(seconds: 1), () async {
      log.info('User stopped interacting, fetching new data...');
      mapbox.CameraState currentCamera = await _mapboxMap.getCameraState();
      _fetchParcelData(
          (currentCamera.center.coordinates[1] as double), // Latitude
          (currentCamera.center.coordinates[0] as double) // Longitude
          );
    });
    log.info('User is interacting with the map...');
  }

  Future<void> _onLocationSelected(SearchResult result) async {
    await _mapboxMap.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: geojson.Position(result.longitude, result.latitude),
        ),
        zoom: 18.0,
      ),
      mapbox.MapAnimationOptions(duration: 1000),
    );
    await _fetchParcelData(result.latitude, result.longitude);
    
    setState(() {
      _isSearchBarVisible = false;
      _isSearchBarActive = false;
      _isBottomSheetVisible = true;
    });
  }

  // BottomSheet UI for selected parcels
  Widget _buildBottomSheet(BuildContext context) {
    final totalArea = _calculateTotalArea();
    final numSelected = _selectedParcels.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      constraints: BoxConstraints(
        maxHeight: numSelected > 1
            ? (_isBottomSheetExpanded
                ? MediaQuery.of(context).size.height * 0.5
                : MediaQuery.of(context).size.height * 0.4)
            : MediaQuery.of(context).size.height * 0.3,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Área Total: $totalArea m²',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    numSelected > 1
                        ? 'Registros Catastrales: $numSelected'
                        : _selectedParcels.values.first,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  if (numSelected > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isBottomSheetExpanded = !_isBottomSheetExpanded;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF388E3C),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 12.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          _isBottomSheetExpanded
                              ? 'Ver menos'
                              : 'Ver más detalles',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (_isBottomSheetExpanded)
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _selectedParcels.length,
                      itemBuilder: (context, index) {
                        final entry = _selectedParcels.entries.toList()[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(
                Icons.copy,
                color: Color(0xFF388E3C),
              ),
              onPressed: _copyToClipboard,
              tooltip: 'Copiar al portapapeles',
            ),
          ),
        ],
      ),
    );
  }

  void _addUserLocationLayer() async {
    if (_currentPosition == null) return;

    const String sourceId = 'user-location-source';
    const String layerId = 'user-location-layer';

    Map<String, dynamic> geoJson = {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          _currentPosition!.longitude,
          _currentPosition!.latitude
        ],
      },
    };

    try {
      // Verificar si el estilo está cargado
      bool isStyleLoaded = await _mapboxMap.style.isStyleLoaded();
      if (!isStyleLoaded) return;

      // Comprobar si la fuente ya existe
      bool sourceExists = await _mapboxMap.style.styleSourceExists(sourceId);
      if (sourceExists) {
        // Actualizar los datos de la fuente
        await _mapboxMap.style.setStyleSourceProperty(
          sourceId,
          'data',
          jsonEncode(geoJson),
        );
      } else {
        // Agregar la fuente
        await _mapboxMap.style.addSource(
          mapbox.GeoJsonSource(
            id: sourceId,
            data: jsonEncode(geoJson),
          ),
        );

        // Agregar la capa de círculo
        await _mapboxMap.style.addLayer(
          mapbox.CircleLayer(
            id: layerId,
            sourceId: sourceId,
            circleColor: const Color(0xFF007AFF).value, // Azul
            circleRadius: 8.0,
            circleOpacity: 0.7,
          ),
        );
      }
    } catch (e) {
      log.severe('Error al actualizar la capa de ubicación del usuario: $e');
    }
  }

  void _copyToClipboard() {
    final StringBuffer buffer = StringBuffer();
    _selectedParcels.forEach((key, value) {
      final parts = value.split(' - ');
      if (parts.length == 2) {
        buffer.writeln('${parts[0]} - ${parts[1]}');
      }
    });

    Clipboard.setData(ClipboardData(text: buffer.toString())).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copiado al portapapeles'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  // Add this method to move the map to the current location
  void _moveToCurrentLocation() async {
    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.best,
        ),
      );
      setState(() {
        _currentPosition = position;
      });
      _updateMapLocation(position.latitude, position.longitude);
      _addUserLocationLayer();
    } catch (e) {
      log.severe('Error getting current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get current location.'),
        ),
      );
    }
  }

  // Implement the _updateUserLocation method
  void _updateUserLocation() async {
    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      log.info(
          '📍 Position obtained: ${position.latitude}, ${position.longitude}, precision: ${position.accuracy} metros');

      if (position.accuracy <= 10) {
        setState(() {
          _currentPosition = position;
        });
        _addUserLocationLayer();
      } else {
        log.warning(
            'Insufficient precision (${position.accuracy}m), the location is not updated');
      }
    } catch (e) {
      log.severe('Error al actualizar la ubicación del usuario: $e');
    }
  }

  void _startLocationUpdates() {
    const locationSettings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 0, // Recibir todas las actualizaciones
    );

    _positionStreamSubscription =
        geo.Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((geo.Position position) {
      log.info(
          'Posición: ${position.latitude}, ${position.longitude}, precisión: ${position.accuracy} metros');
      if (position.accuracy <= 10) {
        _updateUserLocationWithSmoothing(position);
      } else {
        log.warning(
            'Precisión insuficiente (${position.accuracy}m), no se actualiza la ubicación');
      }
    });
  }

  void _updateUserLocationWithSmoothing(geo.Position newPosition) {
    _positionHistory.add(newPosition);
    if (_positionHistory.length > 5) {
      _positionHistory.removeAt(0); // Mantener solo las últimas 5 lecturas
    }

    double avgLatitude =
        _positionHistory.map((p) => p.latitude).reduce((a, b) => a + b) /
            _positionHistory.length;
    double avgLongitude =
        _positionHistory.map((p) => p.longitude).reduce((a, b) => a + b) /
            _positionHistory.length;

    setState(() {
      _currentPosition = geo.Position(
        latitude: avgLatitude,
        longitude: avgLongitude,
        timestamp: newPosition.timestamp,
        accuracy: newPosition.accuracy,
        altitude: newPosition.altitude,
        altitudeAccuracy: newPosition.altitudeAccuracy,
        heading: newPosition.heading,
        headingAccuracy: newPosition.headingAccuracy,
        speed: newPosition.speed,
        speedAccuracy: newPosition.speedAccuracy,
      );
    });

    _addUserLocationLayer();
  }

  // Function to check if content is valid XML
  bool _isValidXmlContent(String content) {
    try {
      return content.trim().startsWith('<?xml') ||
          content.trim().startsWith('<catastro>');
    } catch (e) {
      return false;
    }
  }

  // Function to show error message
  void _showTemporaryMessage() {
    if (!_isErrorMessageVisible) {
      setState(() {
        _isErrorMessageVisible = true;
      });

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isErrorMessageVisible = false;
          });
        }
      });
    }
  }

  // Add method to handle search bar visibility
  void _showSearchBar() {
    if (_isSearchBarVisible) {
      // If search bar is visible, hide it with animation
      _searchBarAnimationController.reverse().then((_) {
        setState(() {
          _isSearchBarVisible = false;
          _isSearchBarActive = false;
          // Show BottomSheet again if there are selected parcels
          if (_selectedParcels.isNotEmpty) {
            _isBottomSheetVisible = true;
          }
        });
      });
    } else {
      // If hidden, show it with animation
      setState(() {
        _isSearchBarVisible = true;
        _isSearchBarActive = false;
        // Hide BottomSheet in landscape mode when search is active
        if (MediaQuery.of(context).orientation == Orientation.landscape) {
          _isBottomSheetVisible = false;
        }
      });
      _searchBarAnimationController.forward();
    }
  }

  // Add new method to handle timer
  void _startSearchBarTimer() {
    _searchBarTimer?.cancel();

    // Only start timer if SearchBar is not active
    if (!_isSearchBarActive) {
      _searchBarTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && !_isSearchBarActive) {
          _searchBarAnimationController.reverse().then((_) {
            setState(() {
              _isSearchBarVisible = false;
            });
          });
        }
      });
    }
  }

  // Añadir método para actualizar el estado activo del SearchBar
  void setSearchBarActive(bool active) {
    setState(() {
      _isSearchBarActive = active;
      // Hide BottomSheet in landscape mode when search is active
      if (active && MediaQuery.of(context).orientation == Orientation.landscape) {
        _isBottomSheetVisible = false;
      }
    });
  }

  // Add method to handle orientation changes
  void _handleOrientationChange(Orientation orientation) {
    if (orientation == Orientation.portrait) {
      setState(() {
        _isBottomSheetVisible = true;
      });
    } else if (_isSearchBarActive) {
      setState(() {
        _isBottomSheetVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle orientation directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleOrientationChange(MediaQuery.of(context).orientation);
    });

    return Scaffold(
      appBar: AppBar(
        iconTheme:
            const IconThemeData(color: Color(0xFF1976D2)), // Add this line
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Parcelas',
                style: TextStyle(color: Color(0xFF1976D2)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF1976D2)),
              onPressed: _showSearchBar,
            ),
            IconButton(
              icon: const Icon(Icons.my_location, color: Color(0xFF1976D2)),
              onPressed: _moveToCurrentLocation,
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE6E6E6),
        foregroundColor: const Color(0xFF1976D2),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Mapbox Map
          mapbox.MapWidget(
            mapOptions: mapbox.MapOptions(
              pixelRatio: MediaQuery.of(context).devicePixelRatio,
            ),
            onMapCreated: (mapbox.MapboxMap mapboxMap) {
              _mapboxMap = mapboxMap;
              _onMapCreated(mapboxMap);
            },
            onTapListener: (context) {
              _onMapClick(context);
              if (_isSearchBarVisible && !_isSearchBarActive) {
                _startSearchBarTimer();
              }
            },
          ),

          // Floating Search Bar with modified logic
          if (_isSearchBarVisible)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: FadeTransition(
                opacity: _searchBarOpacity,
                child: GestureDetector(
                  onTapDown: (_) {
                    _searchBarTimer
                        ?.cancel(); // Cancel timer immediately when touched
                    setState(() {
                      _isSearchBarActive = true;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ExpandableSearchBar(
                      onLocationSelected: (result) {
                        _onLocationSelected(result);
                        _searchBarAnimationController.reverse().then((_) {
                          setState(() {
                            _isSearchBarVisible = false;
                            _isSearchBarActive = false;
                          });
                        });
                        _searchBarTimer?.cancel();
                      },
                    ),
                  ),
                ),
              ),
            ),

          // Loading Spinner
          if (_isFetching)
            Center(
              child: SizedBox(
                width: 60.0,
                height: 60.0,
                child: CircularProgressIndicator(
                  strokeWidth: 6.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
            ),

          // Bottom Sheet
          if (_selectedParcels.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isBottomSheetVisible ? 1.0 : 0.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isBottomSheetVisible ? null : 0,
                  child: _buildBottomSheet(context),
                ),
              ),
            ),
          if (_isErrorMessageVisible)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                key: _errorMessageKey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Las parcelas catastrales no están disponibles. Por favor, inténtelo más tarde',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
        ],
      ),
    );
  }
}
