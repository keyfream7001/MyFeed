import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/feed_source.dart';
import '../models/feed_item.dart';
import '../services/feed_service.dart';
import '../services/storage_service.dart';

class FeedProvider extends ChangeNotifier {
  final FeedService _feedService = FeedService();
  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  List<FeedSource> _sources = [];
  List<FeedItem> _items = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedSourceId;

  List<FeedSource> get sources => _sources;
  List<FeedItem> get items => _filteredItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedSourceId => _selectedSourceId;

  List<FeedItem> get _filteredItems {
    if (_selectedSourceId == null) {
      return _items;
    }
    return _items.where((i) => i.sourceId == _selectedSourceId).toList();
  }

  List<FeedItem> get unreadItems {
    return _items.where((i) => !i.isRead).toList();
  }

  int get unreadCount => unreadItems.length;

  /// Initialize provider and load data from storage
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sources = await _storage.getSources();
      _items = await _storage.getItems();
      _error = null;
    } catch (e) {
      _error = 'Failed to load data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new feed source
  Future<bool> addSource({
    required String name,
    required String url,
    FeedSourceType type = FeedSourceType.rss,
    String? category,
    String? iconUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate the feed URL
      final validation = await _feedService.validateFeedUrl(url);
      if (!validation.isValid) {
        _error = validation.error;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final source = FeedSource(
        id: _uuid.v4(),
        userId: 'local_user',
        name: name.isNotEmpty ? name : (validation.feedTitle ?? 'Unknown Feed'),
        url: url,
        type: type,
        iconUrl: iconUrl ?? validation.feedIcon,
        category: category,
        createdAt: DateTime.now(),
      );

      await _storage.addSource(source);
      _sources.add(source);

      // Fetch initial items
      await _fetchItemsForSource(source);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add source: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove a feed source
  Future<void> removeSource(String sourceId) async {
    try {
      await _storage.removeSource(sourceId);
      _sources.removeWhere((s) => s.id == sourceId);
      _items.removeWhere((i) => i.sourceId == sourceId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove source: $e';
      notifyListeners();
    }
  }

  /// Toggle source active status
  Future<void> toggleSourceActive(String sourceId) async {
    final index = _sources.indexWhere((s) => s.id == sourceId);
    if (index >= 0) {
      _sources[index] = _sources[index].copyWith(
        isActive: !_sources[index].isActive,
      );
      await _storage.updateSource(_sources[index]);
      notifyListeners();
    }
  }

  /// Refresh all feeds
  Future<void> refreshAllFeeds() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final activeSources = _sources.where((s) => s.isActive);
      
      for (final source in activeSources) {
        await _fetchItemsForSource(source);
      }

      _items = await _storage.getItems();
      _error = null;
    } catch (e) {
      _error = 'Failed to refresh feeds: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch items for a single source
  Future<void> _fetchItemsForSource(FeedSource source) async {
    try {
      final items = await _feedService.fetchFeed(source);
      await _storage.addItems(items);

      // Update last fetched time
      final updatedSource = source.copyWith(lastFetchedAt: DateTime.now());
      await _storage.updateSource(updatedSource);
      
      final sourceIndex = _sources.indexWhere((s) => s.id == source.id);
      if (sourceIndex >= 0) {
        _sources[sourceIndex] = updatedSource;
      }
    } catch (e) {
      debugPrint('Failed to fetch ${source.name}: $e');
    }
  }

  /// Filter by source
  void filterBySource(String? sourceId) {
    _selectedSourceId = sourceId;
    notifyListeners();
  }

  /// Mark item as read
  Future<void> markAsRead(String itemId) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(isRead: true);
      await _storage.markItemRead(itemId);
      notifyListeners();
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    _items = _items.map((i) => i.copyWith(isRead: true)).toList();
    await _storage.saveItems(_items);
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
