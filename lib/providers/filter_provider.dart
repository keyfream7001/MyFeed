import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/filter.dart';
import '../models/feed_item.dart';
import '../services/storage_service.dart';

class FilterProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  List<ContentFilter> _filters = [];
  bool _isLoading = false;
  String? _error;

  List<ContentFilter> get filters => _filters;
  List<ContentFilter> get activeFilters => _filters.where((f) => f.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _filters.length;
  int get activeCount => activeFilters.length;

  /// Initialize and load filters from storage
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _filters = await _storage.getFilters();
      _error = null;
    } catch (e) {
      _error = 'Failed to load filters: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new filter
  Future<bool> addFilter({
    required FilterType type,
    required String value,
    FilterAction action = FilterAction.hide,
  }) async {
    try {
      // Check for duplicate
      if (_filters.any((f) => f.type == type && f.value.toLowerCase() == value.toLowerCase())) {
        _error = 'Filter already exists';
        notifyListeners();
        return false;
      }

      final filter = ContentFilter(
        id: _uuid.v4(),
        userId: 'local_user',
        type: type,
        value: value,
        action: action,
        createdAt: DateTime.now(),
      );

      await _storage.addFilter(filter);
      _filters.add(filter);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add filter: $e';
      notifyListeners();
      return false;
    }
  }

  /// Remove a filter
  Future<void> removeFilter(String filterId) async {
    try {
      await _storage.removeFilter(filterId);
      _filters.removeWhere((f) => f.id == filterId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove filter: $e';
      notifyListeners();
    }
  }

  /// Toggle filter active status
  Future<void> toggleFilter(String filterId) async {
    final index = _filters.indexWhere((f) => f.id == filterId);
    if (index >= 0) {
      _filters[index] = _filters[index].copyWith(
        isActive: !_filters[index].isActive,
      );
      await _storage.saveFilters(_filters);
      notifyListeners();
    }
  }

  /// Apply filters to a list of feed items
  List<FeedItem> applyFilters(List<FeedItem> items) {
    if (activeFilters.isEmpty) {
      return items;
    }

    return items.where((item) {
      for (final filter in activeFilters) {
        if (filter.matches(
          item.title,
          item.description,
          item.sourceName,
          item.author,
        )) {
          // If action is hide, remove the item
          if (filter.action == FilterAction.hide) {
            return false;
          }
        }
      }
      return true;
    }).toList();
  }

  /// Check if an item should be muted (shown but dimmed)
  bool shouldMute(FeedItem item) {
    for (final filter in activeFilters) {
      if (filter.action == FilterAction.mute &&
          filter.matches(
            item.title,
            item.description,
            item.sourceName,
            item.author,
          )) {
        return true;
      }
    }
    return false;
  }

  /// Quick add keyword filter
  Future<bool> blockKeyword(String keyword) async {
    return addFilter(
      type: FilterType.keyword,
      value: keyword,
      action: FilterAction.hide,
    );
  }

  /// Quick add source filter
  Future<bool> blockSource(String sourceName) async {
    return addFilter(
      type: FilterType.source,
      value: sourceName,
      action: FilterAction.hide,
    );
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
