import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/media_item.dart';
import '../models/user_profile_data.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_stats_dashboard.dart';

class ProfileTab extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback? onOpenDataManagement;
  final AuthController? authController;
  final SyncService? syncService;
  final VoidCallback? onOpenLogin;
  final VoidCallback? onOpenRegister;
  final VoidCallback? onOpenDeviceManagement;
  final VoidCallback? onClearLibrary;
  final List<MediaItem> mediaItems;
  final UserProfileData userProfile;
  final ValueChanged<UserProfileData>? onProfileUpdated;
  final ValueChanged<MediaItem>? onItemTap;
  final ValueChanged<String>? onIncrementProgress;

  const ProfileTab({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    this.onOpenDataManagement,
    this.authController,
    this.syncService,
    this.onOpenLogin,
    this.onOpenRegister,
    this.onOpenDeviceManagement,
    this.onClearLibrary,
    this.mediaItems = const [],
    this.userProfile = const UserProfileData(),
    this.onProfileUpdated,
    this.onItemTap,
    this.onIncrementProgress,
  });

  void _showClearConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Library Data?'),
        content: const Text(
          'This will remove all saved anime, manga, and TV series from your local library. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onClearLibrary?.call();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will permanently delete your server account and cloud snapshots. Your local library on this device will remain intact as an offline library.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Password required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true && authController != null) {
      final success = await authController!.deleteAccount(
        password: passwordController.text,
      );
      if (context.mounted && !success && authController!.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authController!.errorMessage!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAuthenticated = authController?.isAuthenticated == true;
    final user = authController?.currentUser;
    final syncStatus = syncService?.state ?? SyncStatusState.idle;
    final metadata = syncService?.metadata;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Data, Backup & Transfer',
            onPressed: onOpenDataManagement,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Personal Analytics Hub & Viewing Stats
          ProfileStatsDashboard(
            mediaItems: mediaItems,
            userProfile: userProfile,
            onProfileUpdated: onProfileUpdated,
            onItemTap: onItemTap,
            onIncrementProgress: onIncrementProgress,
          ),

          // Account Status Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF263852) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: ColoredBox(
                    color: theme.colorScheme.primaryContainer,
                    child: SizedBox.square(
                      dimension: 68,
                      child: Icon(
                        isAuthenticated
                            ? Icons.account_circle_rounded
                            : Icons.person_outline_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 38,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAuthenticated
                            ? (user?.email ?? 'Logged In User')
                            : 'Guest User (Offline)',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAuthenticated
                            ? 'Multi-device cloud backup active'
                            : 'Local storage active • Accounts optional',
                        style: TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontSize: 12,
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!isAuthenticated) ...[
                        Row(
                          children: [
                            FilledButton.tonal(
                              onPressed: onOpenLogin,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Sign In'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: onOpenRegister,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Create Account'),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Sync Badge
                        Row(
                          children: [
                            _buildSyncStatusBadge(context, syncStatus),
                            const Spacer(),
                            if (syncService != null)
                              TextButton.icon(
                                onPressed: () {
                                  syncService!.syncNow(boundUserId: user?.id);
                                },
                                icon: const Icon(Icons.sync_rounded, size: 16),
                                label: const Text('Sync Now'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Theme Switcher Tile
          Material(
            color: theme.cardTheme.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              side: BorderSide(
                color:
                    isDark ? const Color(0xFF263852) : const Color(0xFFE2E8F0),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                isDark ? 'Deep Navy visual mode' : 'Soft Indigo light mode',
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: isDark,
              onChanged: (bool value) {
                onThemeModeChanged(value ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          const SizedBox(height: 20),

          // Sync Details Section (If Authenticated)
          if (isAuthenticated && metadata != null) ...[
            Text(
              'Sync Metadata',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF263852)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildMetaRow(
                      context, 'Cloud Revision', 'v${metadata.serverRevision}'),
                  const Divider(height: 16),
                  _buildMetaRow(
                    context,
                    'Last Synced',
                    metadata.lastSuccessfulSyncAt != null
                        ? metadata.lastSuccessfulSyncAt!
                            .toLocal()
                            .toString()
                            .split('.')[0]
                        : 'Never',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Preferences Group
          Text(
            'Preferences',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          Material(
            color: theme.cardTheme.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              side: BorderSide(
                color:
                    isDark ? const Color(0xFF263852) : const Color(0xFFE2E8F0),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildSettingTile(
                  context,
                  icon: Icons.cloud_sync_outlined,
                  title: 'Data, Backup & Transfer',
                  subtitle: 'Import, restore, and save local files',
                  onTap: onOpenDataManagement,
                ),
                if (isAuthenticated) ...[
                  const Divider(height: 1, indent: 56),
                  _buildSettingTile(
                    context,
                    icon: Icons.devices_other_rounded,
                    title: 'Device Management',
                    subtitle: 'Manage active sessions & revoke devices',
                    onTap: onOpenDeviceManagement,
                  ),
                ],
                const Divider(height: 1, indent: 56),
                _buildSettingTile(
                  context,
                  icon: Icons.delete_sweep_rounded,
                  title: 'Clear All Library Data',
                  subtitle: 'Remove all saved media items',
                  iconColor: Colors.redAccent,
                  textColor: Colors.redAccent,
                  onTap: () => _showClearConfirmation(context),
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'About Episode',
                  subtitle: 'v1.0.0 (Offline & Cloud Sync)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Auth Account Actions (If Authenticated)
          if (isAuthenticated) ...[
            Text(
              'Account Actions',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: theme.cardTheme.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF263852)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Log Out'),
                    subtitle: const Text('Keep local data on this device'),
                    onTap: () => authController?.logout(),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.phonelink_erase_rounded),
                    title: const Text('Log Out All Devices'),
                    subtitle: const Text('Revoke sessions on all devices'),
                    onTap: () => authController?.logoutAll(),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Delete Account',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    subtitle: const Text('Permanently delete cloud account'),
                    onTap: () => _handleDeleteAccount(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncStatusBadge(BuildContext context, SyncStatusState status) {
    final theme = Theme.of(context);
    String text = 'Synced';
    Color color = Colors.green;

    switch (status) {
      case SyncStatusState.syncing:
        text = 'Syncing...';
        color = theme.colorScheme.primary;
        break;
      case SyncStatusState.conflictResolving:
        text = 'Resolving conflict...';
        color = Colors.orange;
        break;
      case SyncStatusState.pending:
        text = 'Changes waiting';
        color = Colors.amber.shade800;
        break;
      case SyncStatusState.offline:
        text = 'Offline';
        color = Colors.grey;
        break;
      case SyncStatusState.error:
        text = 'Sync failed';
        color = theme.colorScheme.error;
        break;
      case SyncStatusState.authenticationRequired:
        text = 'Session expired';
        color = theme.colorScheme.error;
        break;
      case SyncStatusState.synced:
      case SyncStatusState.idle:
        text = 'Synced';
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textColor ?? theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Be Vietnam Pro',
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
