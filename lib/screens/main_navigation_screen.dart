import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../controllers/auth_controller.dart';
import '../models/media_item.dart';
import '../repositories/auth_repository.dart';
import '../repositories/local_storage_repository.dart';
import '../services/api_client.dart';
import '../services/auth_token_storage.dart';
import '../services/connectivity_service.dart';
import '../services/device_identity_service.dart';
import '../services/sync_metadata_storage.dart';
import '../services/sync_service.dart';
import 'data_management_screen.dart';
import 'device_management_screen.dart';
import 'home_tab.dart';
import 'login_screen.dart';
import 'manual_media_screen.dart';
import 'media_detail_screen.dart';
import 'profile_tab.dart';
import 'register_screen.dart';
import 'search_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final LocalStorageRepository? storageRepository;
  final AuthController? authController;
  final SyncService? syncService;
  final AuthRepository? authRepository;
  final DeviceIdentityService? deviceIdentityService;

  const MainNavigationScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    this.storageRepository,
    this.authController,
    this.syncService,
    this.authRepository,
    this.deviceIdentityService,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final LocalStorageRepository _storageRepository;
  late final AuthController _authController;
  late final SyncService _syncService;
  late final AuthRepository _authRepository;
  late final DeviceIdentityService _deviceIdentityService;
  ConnectivityService? _connectivityService;

  List<MediaItem> _items = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    const config = AppConfig();
    final tokenStorage = SecureAuthTokenStorage();
    _deviceIdentityService =
        widget.deviceIdentityService ?? DeviceIdentityService();
    final apiClient = ApiClient(config: config, tokenStorage: tokenStorage);

    _authRepository = widget.authRepository ??
        AuthRepository(
          apiClient: apiClient,
          tokenStorage: tokenStorage,
          deviceIdentityService: _deviceIdentityService,
        );

    _authController = widget.authController ??
        AuthController(authRepository: _authRepository);

    final metadataStorage = SyncMetadataStorage();

    _syncService = widget.syncService ??
        SyncService(
          apiClient: apiClient,
          storageRepository:
              widget.storageRepository ?? const LocalStorageRepository(),
          metadataStorage: metadataStorage,
          deviceIdentityService: _deviceIdentityService,
        );

    _storageRepository = widget.storageRepository ??
        LocalStorageRepository(
          onLocalDataChanged: () {
            _syncService.markLocalChangePending();
          },
        );

    _authController.addListener(_onAuthOrSyncStateChanged);
    _syncService.addListener(_onAuthOrSyncStateChanged);

    _connectivityService = ConnectivityService(syncService: _syncService);
    _connectivityService?.startListening(
      boundUserId: _authController.currentUser?.id,
    );

    _initApp();
  }

  Future<void> _initApp() async {
    await _loadItems();
    await _authController.restoreSession();
    if (_authController.isAuthenticated) {
      await _syncService.syncNow(boundUserId: _authController.currentUser?.id);
      await _loadItems();
    }
  }

  void _onAuthOrSyncStateChanged() {
    if (mounted) {
      setState(() {});
      _loadItems();
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthOrSyncStateChanged);
    _syncService.removeListener(_onAuthOrSyncStateChanged);
    _connectivityService?.stopListening();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final loaded = await _storageRepository.loadMediaItems();
      if (mounted) {
        setState(() {
          _items = loaded;
          _isLoading = false;
          _loadError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'The stored library could not be read. Restore a valid '
              'backup or retry without clearing the existing data.';
        });
      }
    }
  }

  Future<void> _incrementProgress(String id) async {
    final updatedList = await _storageRepository.incrementProgress(id);
    if (mounted) {
      setState(() {
        _items = updatedList;
      });
    }
  }

  Future<void> _addToLibrary(MediaItem newItem) async {
    final updatedList = await _storageRepository.saveMediaItem(newItem);
    if (mounted) {
      setState(() {
        _items = updatedList;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${newItem.title}" to your Home Library!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateItem(MediaItem updatedItem) async {
    final updatedList = await _storageRepository.updateMediaItem(updatedItem);
    if (mounted) {
      setState(() {
        _items = updatedList;
      });
    }
  }

  Future<void> _deleteItem(String id) async {
    final updatedList = await _storageRepository.deleteMediaItem(id);
    if (mounted) {
      setState(() {
        _items = updatedList;
      });
    }
  }

  void _openDetailScreen(MediaItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(
          item: item,
          onSave: _updateItem,
          onDelete: _deleteItem,
        ),
      ),
    );
  }

  void _openManualMediaScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManualMediaScreen(onSave: _addToLibrary),
      ),
    );
  }

  void _openDataManagementScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DataManagementScreen(
          mediaItems: _items,
          storageRepository: _storageRepository,
          onLibraryChanged: (items) {
            if (mounted) {
              setState(() => _items = items);
            }
          },
        ),
      ),
    );
  }

  void _openLoginScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          authController: _authController,
          syncService: _syncService,
          storageRepository: _storageRepository,
        ),
      ),
    );
  }

  void _openRegisterScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegisterScreen(
          authController: _authController,
          syncService: _syncService,
          storageRepository: _storageRepository,
        ),
      ),
    );
  }

  void _openDeviceManagementScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeviceManagementScreen(
          authRepository: _authRepository,
          deviceIdentityService: _deviceIdentityService,
          onCurrentDeviceRevoked: () {
            _authController.logout();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storage_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Library recovery needed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(_loadError!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _loadItems();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final pages = [
      HomeTab(
        mediaItems: _items,
        onIncrementProgress: _incrementProgress,
        onItemTap: _openDetailScreen,
        onAddManually: _openManualMediaScreen,
      ),
      SearchTab(
        existingItems: _items,
        onAddToLibrary: _addToLibrary,
        onAddManually: _openManualMediaScreen,
      ),
      ProfileTab(
        currentThemeMode: widget.currentThemeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onOpenDataManagement: _openDataManagementScreen,
        authController: _authController,
        syncService: _syncService,
        onOpenLogin: _openLoginScreen,
        onOpenRegister: _openRegisterScreen,
        onOpenDeviceManagement: _openDeviceManagementScreen,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
