import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';
import '../services/device_identity_service.dart';

class DeviceManagementScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final DeviceIdentityService deviceIdentityService;
  final VoidCallback onCurrentDeviceRevoked;

  const DeviceManagementScreen({
    super.key,
    required this.authRepository,
    required this.deviceIdentityService,
    required this.onCurrentDeviceRevoked,
  });

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  List<DeviceSummary> _devices = [];
  String? _currentClientDeviceId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clientDeviceId =
          await widget.deviceIdentityService.getOrCreateClientDeviceId();
      final devices = await widget.authRepository.getDevices();

      if (mounted) {
        setState(() {
          _currentClientDeviceId = clientDeviceId;
          _devices = devices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load devices: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _revokeDevice(DeviceSummary device) async {
    final isCurrent = device.clientDeviceId == _currentClientDeviceId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revoke ${device.name}?'),
        content: Text(
          isCurrent
              ? 'This will sign out your current device. Local data will remain on this device.'
              : 'This device will no longer be able to sync until signed in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.authRepository.revokeDevice(device.id);
      if (isCurrent) {
        widget.onCurrentDeviceRevoked();
        if (mounted) Navigator.of(context).pop();
      } else {
        await _loadDevices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke device: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadDevices,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _devices.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isCurrent =
                        device.clientDeviceId == _currentClientDeviceId;

                    return ListTile(
                      leading: Icon(
                        isCurrent
                            ? Icons.phone_android_rounded
                            : Icons.devices_rounded,
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              device.name,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'This Device',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${device.platform} ${device.appVersion != null ? "v${device.appVersion}" : ""} • ${device.isActive ? "Active" : "Revoked"}',
                        style: TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: device.isActive
                          ? IconButton(
                              icon: const Icon(
                                  Icons.remove_circle_outline_rounded),
                              color: theme.colorScheme.error,
                              tooltip: 'Revoke Device',
                              onPressed: () => _revokeDevice(device),
                            )
                          : const Chip(
                              label: Text('Revoked'),
                              visualDensity: VisualDensity.compact,
                            ),
                    );
                  },
                ),
    );
  }
}
