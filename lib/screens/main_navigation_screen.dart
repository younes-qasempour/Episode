import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../repositories/local_storage_repository.dart';
import 'home_tab.dart';
import 'search_tab.dart';
import 'profile_tab.dart';
import 'media_detail_screen.dart';
import 'manual_media_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final LocalStorageRepository? storageRepository;

  const MainNavigationScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    this.storageRepository,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final LocalStorageRepository _storageRepository;
  List<MediaItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _storageRepository = widget.storageRepository ?? LocalStorageRepository();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final loaded = await _storageRepository.loadMediaItems();
    if (mounted) {
      setState(() {
        _items = loaded;
        _isLoading = false;
      });
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

  Future<void> _clearLibrary() async {
    final updatedList = await _storageRepository.clearAllMediaItems();
    if (mounted) {
      setState(() {
        _items = updatedList;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Library cleared successfully!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        onClearLibrary: _clearLibrary,
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
