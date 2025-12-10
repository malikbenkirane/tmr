import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

class SharedDatabaseService {
  SharedDatabaseService();

  static const String _appGroupId = 'group.com.example.tooManyTabs';
  static const String _sharedDefaultsKey = 'shared_database_path';

  static const MethodChannel _channel = MethodChannel(
    'com.example.tooManyTabs/share',
  );

  final _log = Logger('SharehShareHandlerService');

  /// Initialize the service and set up listeners
  Future<void> initialize() async {
    if (Platform.isIOS) {
      // Check for shared database on app launch
      await checkForSharedDatabase();

      // Set up method call handler for URL scheme
      _channel.setMethodCallHandler(_handleMethodCall);
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'handleSharedDatabase') {
      await checkForSharedDatabase();
    }
  }

  /// Check if there's a shared database from the Share Extension
  Future<String?> checkForSharedDatabase() async {
    if (!Platform.isIOS) return null;

    try {
      // Access App Group UserDefaults
      final String? sharedPath = await _getSharedDatabasePath();

      if (sharedPath != null && await File(sharedPath).exists()) {
        return sharedPath;
      }
    } catch (e) {
      _log.warning('Error checking for shared database: $e');
    }

    return null;
  }

  /// Get the shared database path from App Group UserDefaults
  Future<String?> _getSharedDatabasePath() async {
    try {
      final result = await _channel.invokeMethod<String>(
        'getSharedDatabasePath',
        {'appGroupId': _appGroupId, 'key': _sharedDefaultsKey},
      );
      return result;
    } catch (e) {
      _log.warning('Error getting shared database path: $e');
      return null;
    }
  }

  /// Import the shared database to replace the current one
  Future<bool> importSharedDatabase({
    required String sharedPath,
    required String currentDatabasePath,
    required Function() onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final sharedFile = File(sharedPath);

      // Validate the file exists
      if (!await sharedFile.exists()) {
        onError('Shared database file not found');
        return false;
      }

      // Validate it's a SQLite database (basic check)
      final bytes = await sharedFile.readAsBytes();
      if (bytes.length < 16 ||
          String.fromCharCodes(bytes.sublist(0, 16)) !=
              'SQLite format 3\u0000') {
        onError('Invalid SQLite database file');
        return false;
      }

      // Backup current database
      final currentFile = File(currentDatabasePath);
      if (await currentFile.exists()) {
        final backupPath =
            '$currentDatabasePath.backup_${DateTime.now().millisecondsSinceEpoch}';
        await currentFile.copy(backupPath);
      }

      // Replace the current database
      await sharedFile.copy(currentDatabasePath);

      // Clean up the shared file
      await sharedFile.delete();
      await _clearSharedDatabasePath();

      onSuccess();
      return true;
    } catch (e) {
      onError('Failed to import database: $e');
      return false;
    }
  }

  /// Clear the shared database path from App Group UserDefaults
  Future<void> _clearSharedDatabasePath() async {
    try {
      await _channel.invokeMethod('clearSharedDatabasePath', {
        'appGroupId': _appGroupId,
        'key': _sharedDefaultsKey,
      });
    } catch (e) {
      _log.warning('Error clearing shared database path: $e');
    }
  }
}
