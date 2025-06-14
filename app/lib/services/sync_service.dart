import 'dart:async';
import 'package:quran_echo/services/api_service.dart';
import 'package:quran_echo/utils/offline_storage.dart';

class SyncService {
  static bool _isSyncing = false;
  static Timer? _syncTimer;
  
  // Start background sync process
  static void startBackgroundSync() {
    // Stop any existing timer
    _syncTimer?.cancel();
    
    // Set up periodic sync every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      syncPendingUpdates();
    });
    
    // Also run immediate sync
    syncPendingUpdates();
  }
  
  // Stop background sync
  static void stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  // Sync all pending updates
  static Future<void> syncPendingUpdates() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    
    try {
      // Check if we can connect to the server
      final connected = await ApiService.initialize();
      if (!connected) {
        _isSyncing = false;
        return;
      }
      
      // Get all pending updates
      final pendingUpdates = await OfflineStorage.getPendingUpdates();
      
      for (int i = 0; i < pendingUpdates.length; i++) {
        final update = pendingUpdates[i];
        final endpoint = update['endpoint'] as String;
        final data = update['data'] as Map<String, dynamic>;
        
        try {
          // Try to send the update to the server
          if (endpoint.contains('/memorized-ayats') || 
              endpoint.contains('/surah-progress') ||
              endpoint.contains('/weekly-progress')) {
            await ApiService.put(endpoint, data);
          } else if (endpoint.contains('/add-time')) {
            await ApiService.post(endpoint, data);
          }
          
          // If successful, remove the update from pending list
          await OfflineStorage.removePendingUpdate(i);
          i--; // Adjust index since we removed an item
        } catch (e) {
          print('Failed to sync update $endpoint: $e');
          // If this update fails, skip to the next one
          continue;
        }
      }
    } catch (e) {
      print('Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }
}