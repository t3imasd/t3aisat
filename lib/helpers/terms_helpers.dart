import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'package:flutter/widgets.dart';

Future<String> loadTermsFromFile(BuildContext context) async {
  final logger = Logger('TermsHelper');
  
  try {
    logger.info('Starting terms loading from path: assets/documents/privacy_policy_t3aisat.md');
    
    // Log asset bundle info
    final bundle = DefaultAssetBundle.of(context);
    final manifestContent = await bundle.loadString('AssetManifest.json');
    logger.info('Asset manifest contents: $manifestContent');
    
    // Try loading with both methods
    String content;
    try {
      content = await rootBundle.loadString(
        'assets/documents/privacy_policy_t3aisat.md',
        cache: false
      );
    } catch (e) {
      logger.warning('rootBundle failed, trying DefaultAssetBundle');
      content = await bundle.loadString('assets/documents/privacy_policy_t3aisat.md');
    }
    
    logger.info('Successfully loaded terms with length: ${content.length}');
    return content;
  } catch (e, stack) {
    logger.severe('Failed to load terms', e, stack);
    rethrow;
  }
}
