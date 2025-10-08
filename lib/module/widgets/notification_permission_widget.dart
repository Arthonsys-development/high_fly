import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/module/providers/fcm_provider.dart';

class NotificationPermissionWidget extends ConsumerStatefulWidget {
  const NotificationPermissionWidget({super.key});

  @override
  ConsumerState<NotificationPermissionWidget> createState() => _NotificationPermissionWidgetState();
}

class _NotificationPermissionWidgetState extends ConsumerState<NotificationPermissionWidget> {
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _token;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fcmService = ref.read(fcmProvider);
      final hasPermission = await fcmService.checkNotificationPermission();
      
      setState(() {
        _hasPermission = hasPermission;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error checking permission: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fcmService = ref.read(fcmProvider);
      final permissionGranted = await fcmService.requestNotificationPermission();
      
      if (permissionGranted) {
        // Get FCM token after permission is granted
        final token = await fcmService.getFcmToken();
        if (token != null) {
          // Register token with backend
          await fcmService.registerToken(token);
        }
        
        setState(() {
          _hasPermission = true;
          _token = token;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error requesting permission: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _hasPermission
                  ? 'Notifications are enabled'
                  : 'Notifications are disabled',
              style: TextStyle(
                color: _hasPermission ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _requestPermission,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Request Permission'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkPermissionStatus,
                  child: const Text('Check Permission'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (_token != null) ...[
              const SizedBox(height: 16),
              const Text('FCM Token:'),
              Text(
                _token!,
                style: const TextStyle(fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}