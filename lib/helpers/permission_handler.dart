import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

/// Helper class for managing app permissions
class PermissionHelper {
  static final Logger _logger = Logger('PermissionHelper');
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const String _permissionPrefsKey = 'permission_requests';

  // Updated dialog style constants
  static const _dialogBorderRadius = 16.0;
  static const _iconSize = 48.0;
  static const _contentPadding = EdgeInsets.all(24.0);
  
  static const _dialogTheme = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(_dialogBorderRadius)),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );

  // Add these constants after other static constants
  static const _minButtonTextSize = 14.0;
  static const _maxButtonTextSize = 16.0;
  static const _buttonTextScaleFactor = 0.04; // 4% of button width
  static const _defaultButtonPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const _minButtonPadding = EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0);
  
  // Add this helper method after the constants
  static double _calculateButtonTextSize(double buttonWidth) {
    final calculatedSize = buttonWidth * _buttonTextScaleFactor;
    return calculatedSize.clamp(_minButtonTextSize, _maxButtonTextSize);
  }

  static Icon _getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return const Icon(Icons.camera_alt_rounded, 
          size: _iconSize, color: Color(0xFF4CAF50));
      case Permission.microphone:
        return const Icon(Icons.mic_rounded, 
          size: _iconSize, color: Color(0xFF2196F3));
      case Permission.photos:
      case Permission.videos:
      case Permission.storage:
        return const Icon(Icons.photo_library_rounded, 
          size: _iconSize, color: Color(0xFF9C27B0));
      case Permission.locationWhenInUse:
      case Permission.location:
        return const Icon(Icons.location_on_rounded, 
          size: _iconSize, color: Color(0xFFFF9800));
      default:
        return const Icon(Icons.settings, 
          size: _iconSize, color: Color(0xFF757575));
    }
  }

  static Widget _buildPermissionDialog({
    required String title,
    required List<Permission> permissions,
    required String feature,
    required List<Widget> actions,
    String? additionalInfo,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_dialogBorderRadius),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: _dialogTheme,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: _contentPadding,
                child: Column(
                  children: [
                    ...permissions.map((permission) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: _getPermissionIcon(permission),
                        title: Text(
                          _getPermissionName(permission),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          _getDetailedPermissionExplanation(permission, feature),
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            height: 1.3,
                          ),
                        ),
                      ),
                    )),
                    if (additionalInfo != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          additionalInfo,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8.0),
                    actions[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Almacena información sobre los intentos de solicitud de permisos
  static Future<void> _savePermissionRequest(Permission permission) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = prefs.getStringList(_permissionPrefsKey) ?? [];
    requests.add(permission.value.toString());
    await prefs.setStringList(_permissionPrefsKey, requests);
  }

  // Verifica si un permiso ya ha sido solicitado anteriormente
  static Future<bool> _hasRequestedPermission(Permission permission) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = prefs.getStringList(_permissionPrefsKey) ?? [];
    return requests.contains(permission.value.toString());
  }

  /// Initialize permissions system
  static Future<void> initializePermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_permissionPrefsKey)) {
        await prefs.setStringList(_permissionPrefsKey, []);
      }
    } catch (e) {
      _logger.severe('Error initializing permissions: $e');
    }
  }

  /// Gets required permissions based on feature and platform version
  static Future<List<Permission>> getRequiredPermissions(String feature) async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (feature == 'camera') {
          // Para Captura con ubicación
          if (sdkInt >= 33) {
            // Group photos and videos as one permission request
            return [
              Permission.camera,
              Permission.microphone,
              Permission
                  .photos, // This will handle both photos and videos on Android 13+
              Permission.locationWhenInUse,
            ];
          } else {
            return [
              Permission.camera,
              Permission.microphone,
              Permission.storage, // Single storage permission for Android < 13
              Permission.locationWhenInUse,
            ];
          }
        } else {
          return [Permission.locationWhenInUse];
        }
      }

      if (Platform.isIOS) {
        if (feature == 'camera') {
          return [
            Permission.camera,
            Permission.microphone,
            Permission
                .photos, // Single photos permission handles both photos and videos on iOS
            Permission.locationWhenInUse,
          ];
        } else {
          return [Permission.locationWhenInUse];
        }
      }

      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'Plataforma no soportada',
      );
    } catch (e) {
      _logger.severe('Error getting required permissions: $e');
      rethrow;
    }
  }

  // Muestra un diálogo explicativo personalizado
  static Future<bool> showPermissionDialog(
    BuildContext context,
    String permissionName,
    String explanation,
  ) async {
    final permission = _getPermissionFromName(permissionName);
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPermissionDialog(
        title: 'Permiso necesario',
        permissions: [permission],
        feature: '',
        actions: [
          _buildActionButton(
            text: 'Ahora no',
            onPressed: () => Navigator.of(context).pop(false),
            isPrimary: false,
            context: context,
          ),
          _buildActionButton(
            text: 'Continuar',
            onPressed: () => Navigator.of(context).pop(true),
            isPrimary: true,
            context: context,
          ),
        ],
      ),
    ) ?? false;
  }

  // Add this helper method to convert permission name to Permission object
  static Permission _getPermissionFromName(String permissionName) {
    switch (permissionName.toLowerCase()) {
      case 'cámara':
        return Permission.camera;
      case 'micrófono':
        return Permission.microphone;
      case 'galería':
        return Platform.isAndroid && _getSdkVersion() >= 33
            ? Permission.photos
            : Permission.storage;
      case 'ubicación':
        return Permission.locationWhenInUse;
      default:
        return Permission.storage;
    }
  }

  // Add helper method to get Android SDK version
  static int _getSdkVersion() {
    if (Platform.isAndroid) {
      return int.tryParse(Platform.operatingSystemVersion.split('.').first) ?? 0;
    }
    return 0;
  }

  /// Request permissions sequentially
  static Future<Map<Permission, PermissionStatus>> requestPermissions(
    BuildContext context,
    List<Permission> permissions,
    String feature, // Añadir este parámetro
  ) async {
    Map<Permission, PermissionStatus> statuses = {};

    // Primero solicitar locationWhenInUse
    if (permissions.contains(Permission.locationWhenInUse)) {
      statuses[Permission.locationWhenInUse] = await _requestSinglePermission(
          context, Permission.locationWhenInUse, feature); // Pasar feature aquí

      // Si locationWhenInUse fue concedido, solicitar locationAlways si es necesario
      if (statuses[Permission.locationWhenInUse]?.isGranted == true &&
          permissions.contains(Permission.locationAlways)) {
        if (context.mounted) {
          statuses[Permission.locationAlways] = await _requestSinglePermission(
              context,
              Permission.locationAlways,
              feature); // Pasar feature aquí
        }
      }
    }

    // Solicitar el resto de permisos
    for (var permission in permissions) {
      if (permission != Permission.locationWhenInUse &&
          permission != Permission.locationAlways) {
        if (context.mounted) {
          statuses[permission] = await _requestSinglePermission(
              context, permission, feature); // Pasar feature aquí
        }
      }
    }

    return statuses;
  }

  /// Request a single permission with context
  static Future<PermissionStatus> _requestSinglePermission(
    BuildContext context,
    Permission permission,
    String feature,
  ) async {
    try {
      final status = await permission.status;

      if (status.isGranted) return status;
      if (status.isPermanentlyDenied) return status;

      // Check if this is a media permission that was already requested
      if ((permission == Permission.photos ||
              permission == Permission.videos) &&
          await _hasRequestedPermission(Permission.photos)) {
        return status;
      }

      if (!await _hasRequestedPermission(permission)) {
        // For photos/videos permissions, show a single dialog
        if (permission == Permission.videos &&
            await _hasRequestedPermission(Permission.photos)) {
          return status;
        }

        final shouldRequest = await showPermissionDialog(
          context,
          _getPermissionName(permission),
          _getDetailedPermissionExplanation(permission, feature),
        );

        if (shouldRequest) {
          final newStatus = await permission.request();
          await _savePermissionRequest(permission);

          // If photos permission is granted, also mark videos as requested
          if (permission == Permission.photos) {
            await _savePermissionRequest(Permission.videos);
          }

          return newStatus;
        }
      }

      return status;
    } catch (e) {
      _logger
          .severe('Error requesting permission ${permission.toString()}: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request location permissions sequentially
  static Future<Map<Permission, PermissionStatus>> requestLocationPermissions(
    BuildContext context,
  ) async {
    Map<Permission, PermissionStatus> statuses = {};

    try {
      // First request locationWhenInUse
      if (await _shouldRequestPermission(Permission.locationWhenInUse)) {
        final whenInUseStatus = await Permission.locationWhenInUse.request();
        statuses[Permission.locationWhenInUse] = whenInUseStatus;

        // Only request locationAlways if whenInUse was granted
        if (whenInUseStatus.isGranted) {
          final shouldRequestAlways = await showPermissionDialog(
            context,
            'ubicación en segundo plano',
            _getDetailedPermissionExplanation(Permission.locationAlways),
          );

          if (shouldRequestAlways) {
            final alwaysStatus = await Permission.locationAlways.request();
            statuses[Permission.locationAlways] = alwaysStatus;
          }
        }
      }
    } catch (e) {
      _logger.severe('Error requesting location permissions: $e');
    }

    return statuses;
  }

  // Actualizar el método para explicaciones más detalladas
  static String _getDetailedPermissionExplanation(Permission permission,
      [String? context]) {
    final bool isIOS = Platform.isIOS;

    switch (permission) {
      case Permission.camera:
        return 'Captura fotos o videos geolocalizados para documentar tus proyectos.';
      case Permission.microphone:
        return 'El acceso al micrófono te permite grabar notas de voz durante la captura de videos, facilitando la documentación detallada de inspecciones, peritajes o validaciones en campo.';
      case Permission.photos:
      case Permission.videos:
      case Permission.storage:
        return isIOS
            ? 'Guarda y consulta tus fotos o videos con información geolocalizada.'
            : 'Guarda y consulta tus fotos o videos con información geolocalizada.';
      case Permission.locationWhenInUse:
      case Permission.location:
        return context == 'camera'
            ? 'Añade ubicación precisa a tus fotos y videos.'
            : 'Visualiza tu posición y las parcelas en el mapa.';
      default:
        return 'Necesario para el funcionamiento de la app.';
    }
  }

  /// Check if permission should be requested
  static Future<bool> _shouldRequestPermission(Permission permission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requests = prefs.getStringList(_permissionPrefsKey) ?? [];
      return !requests.contains(permission.value.toString());
    } catch (e) {
      _logger.warning('Error checking permission request history: $e');
      return true;
    }
  }

  // Verifica si todos los permisos están concedidos
  static Future<bool> checkAllPermissions() async {
    final permissions = await getRequiredPermissions('camera');

    for (var permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        _logger
            .info('Permission not granted: ${_getPermissionName(permission)}');
        return false;
      }
    }
    return true;
  }

  /// Handle permanently denied permissions with detailed explanations
  static Future<void> handlePermanentlyDeniedPermissions(
    BuildContext context,
    List<Permission> deniedPermissions,
  ) async {
    if (deniedPermissions.isEmpty) return;

    String platformSpecificInstructions = await _getPlatformSpecificInstructions();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPermissionDialog(
        title: 'Permisos necesarios',
        permissions: deniedPermissions,
        feature: '',
        additionalInfo: platformSpecificInstructions,
        actions: [
          _buildActionButton(
            text: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(false),
            isPrimary: false,
            context: context,
          ),
          _buildActionButton(
            text: 'Ajustes',  // Changed from 'Abrir Ajustes'
            onPressed: () {
              Navigator.of(context).pop(true);
              openAppSettings();
            },
            isPrimary: true,
            context: context,
          ),
        ],
      ),
    );

    if (result ?? false) {
      await openAppSettings();
    }
  }

  static Future<String> _getPlatformSpecificInstructions() async {
    if (Platform.isIOS) {
      return '1. Abre Configuración > Privacidad y seguridad > T3 AI SAT\n'
          '2. Activa los permisos necesarios';
    } else {
      final androidInfo = await _deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        return '1. Abre Ajustes > Privacidad y seguridad > Permisos > T3 AI SAT\n'
            '2. Activa los permisos necesarios para cada función';
      } else {
        return '1. Abre Ajustes > Aplicaciones > T3 AI SAT > Permisos\n'
            '2. Activa los permisos necesarios';
      }
    }
  }

  // Actualizar el método para devolver nombres unificados
  static String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Cámara';
      case Permission.microphone:
        return 'Micrófono';
      case Permission.photos:
      case Permission.videos:
      case Permission.storage:
        return 'Galería';
      case Permission.locationWhenInUse:
      case Permission.location:
        return 'Ubicación';
      default:
        return 'Permiso desconocido';
    }
  }

  /// Shows a dialog for denied permissions and returns whether to continue
  static Future<bool> showDeniedPermissionsDialog(
    BuildContext context,
    List<Permission> deniedPermissions,
    String feature,
  ) async {
    final canOpenSettings = await openAppSettings().then((_) => true).catchError((_) => false);
    String instructions = await _getPlatformSpecificInstructions();

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPermissionDialog(
        title: 'Permisos Requeridos',
        permissions: deniedPermissions,
        feature: feature,
        additionalInfo: instructions,
        actions: [
          _buildActionButton(
            text: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(false),
            isPrimary: false,
            context: context,
          ),
          if (canOpenSettings)
            _buildActionButton(
              text: 'Ajustes',
              onPressed: () {
                Navigator.of(context).pop(true);
                openAppSettings();
              },
              isPrimary: true,
              context: context,
            )
          else
            _buildActionButton(
              text: 'Entendido',
              onPressed: () => Navigator.of(context).pop(true),
              isPrimary: true,
              context: context,
            ),
        ],
      ),
    ) ?? false;
  }

  /// Shows initial informative dialog for permissions that haven't been requested yet
  static Future<bool> showInitialPermissionsDialog(
    BuildContext context,
    List<Permission> permissions,
    String feature,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPermissionDialog(
        title: 'Permisos Necesarios',
        permissions: permissions,
        feature: feature,
        actions: [
          _buildActionButton(
            text: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(false),
            isPrimary: false,
            context: context,
          ),
          _buildActionButton(
            text: 'Continuar',
            onPressed: () => Navigator.of(context).pop(true),
            isPrimary: true,
            context: context,
          ),
        ],
      ),
    ) ?? false;
  }

  /// Handle denied permissions specifically
  static Future<void> handleDeniedPermissions(
    BuildContext context,
    List<Permission> deniedPermissions,
    String feature,
  ) async {
    String instructions = await _getPlatformSpecificInstructions();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPermissionDialog(
        title: 'Permisos Denegados',
        permissions: deniedPermissions,
        feature: feature,
        additionalInfo: instructions,
        actions: [
          _buildActionButton(
            text: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(),
            isPrimary: false,
            context: context,
          ),
          _buildActionButton(
            text: 'Ajustes',
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            isPrimary: true,
            context: context,
          ),
        ],
      ),
    );
  }

  /// Check if a permission has been requested before
  static Future<bool> hasBeenRequested(Permission permission) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = prefs.getStringList(_permissionPrefsKey) ?? [];
    return requests.contains(permission.value.toString());
  }

  // Modify the ElevatedButton builder in all action buttons
  // Example for one button (apply similar pattern to all):
  static Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = false,
    BuildContext? context,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSize = _calculateButtonTextSize(constraints.maxWidth);
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(fontSize: textSize),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);
        
        final textWidth = textPainter.width;
        final buttonPadding = (textWidth + 32.0 > constraints.maxWidth) 
            ? _minButtonPadding 
            : _defaultButtonPadding;
        
        final buttonStyle = isPrimary 
            ? ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: buttonPadding,
                minimumSize: const Size(0, 48), // Add minimum height
              )
            : ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)),
                minimumSize: WidgetStateProperty.all(const Size(0, 36)), // Smaller height for secondary
              );

        return isPrimary 
          ? ElevatedButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: Text(
                text,
                style: TextStyle(fontSize: textSize),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : TextButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: Text(
                text,
                style: TextStyle(fontSize: _minButtonTextSize),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
      },
    );
  }
}
