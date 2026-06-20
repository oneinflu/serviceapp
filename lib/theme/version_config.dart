import 'package:dio/dio.dart';

class VersionCheckResult {
  final bool hasUpdate;
  final bool forceUpdate;
  final String updateUrl;
  final String latestVersion;

  VersionCheckResult({
    required this.hasUpdate,
    required this.forceUpdate,
    required this.updateUrl,
    required this.latestVersion,
  });
}

class VersionConfig {
  /// Local version of the app. Should match the version in pubspec.yaml.
  static const String currentVersion = '1.0.4';

  /// Endpoint URL to query the latest version info.
  static const String versionCheckUrl = 'https://servicebackendnew-e2d8v.ondigitalocean.app/api/app-version';

  /// Default update URL (e.g. Play Store page) if not returned by the backend.
  static const String defaultUpdateUrl = 'https://play.google.com/store/apps/details?id=com.serviceinfotek.app';

  /// Performs the network call and checks if the app needs to be updated.
  static Future<VersionCheckResult> checkAppVersion() async {
    final dio = Dio();
    try {
      final response = await dio.get(
        versionCheckUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 4),
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['status'] == 'success') {
          final verData = data['data'];
          final latestVersion = verData['latestVersion'] as String;
          final forceUpdate = verData['forceUpdate'] as bool? ?? false;
          final updateUrl = verData['updateUrl'] as String? ?? defaultUpdateUrl;

          bool isOld = _isVersionOlder(currentVersion, latestVersion);
          return VersionCheckResult(
            hasUpdate: isOld,
            forceUpdate: forceUpdate,
            updateUrl: updateUrl,
            latestVersion: latestVersion,
          );
        }
      }
    } catch (e) {
      print('Error checking app version: $e');
    }
    return VersionCheckResult(
      hasUpdate: false,
      forceUpdate: false,
      updateUrl: defaultUpdateUrl,
      latestVersion: currentVersion,
    );
  }

  static bool _isVersionOlder(String current, String latest) {
    try {
      List<int> currentParts = current.split('+')[0].split('.').map(int.parse).toList();
      List<int> latestParts = latest.split('+')[0].split('.').map(int.parse).toList();

      int maxLength = currentParts.length > latestParts.length ? currentParts.length : latestParts.length;
      for (int i = 0; i < maxLength; i++) {
        int currentVal = i < currentParts.length ? currentParts[i] : 0;
        int latestVal = i < latestParts.length ? latestParts[i] : 0;
        if (currentVal < latestVal) return true;
        if (currentVal > latestVal) return false;
      }
    } catch (e) {
      print('Error comparing versions: $e');
    }
    return false;
  }
}

