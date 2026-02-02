import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feed_source.dart';
import '../models/feed_item.dart';
import '../models/filter.dart';
import '../models/bookmark.dart';

/// Local storage service using SharedPreferences
/// MVP uses local storage, can be replaced with Supabase later
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _sourcesKey = 'feed_sources';
  static const String _itemsKey = 'feed_items';
  static const String _bookmarksKey = 'bookmarks';
  static const String _filtersKey = 'filters';
  static const String _settingsKey = 'settings';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Feed Sources
  Future<List<FeedSource>> getSources() async {
    final p = await prefs;
    final jsonStr = p.getString(_sourcesKey);
    if (jsonStr == null) return [];

    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => FeedSource.fromJson(e)).toList();
  }

  Future<void> saveSources(List<FeedSource> sources) async {
    final p = await prefs;
    final jsonStr = jsonEncode(sources.map((e) => e.toJson()).toList());
    await p.setString(_sourcesKey, jsonStr);
  }

  Future<void> addSource(FeedSource source) async {
    final sources = await getSources();
    sources.add(source);
    await saveSources(sources);
  }

  Future<void> removeSource(String sourceId) async {
    final sources = await getSources();
    sources.removeWhere((s) => s.id == sourceId);
    await saveSources(sources);

    // Also remove related items
    final items = await getItems();
    items.removeWhere((i) => i.sourceId == sourceId);
    await saveItems(items);
  }

  Future<void> updateSource(FeedSource source) async {
    final sources = await getSources();
    final index = sources.indexWhere((s) => s.id == source.id);
    if (index >= 0) {
      sources[index] = source;
      await saveSources(sources);
    }
  }

  // Feed Items
  Future<List<FeedItem>> getItems() async {
    final p = await prefs;
    final jsonStr = p.getString(_itemsKey);
    if (jsonStr == null) return [];

    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => FeedItem.fromJson(e)).toList();
  }

  Future<void> saveItems(List<FeedItem> items) async {
    final p = await prefs;
    // Keep only last 500 items to prevent storage bloat
    final trimmed = items.length > 500 ? items.sublist(0, 500) : items;
    final jsonStr = jsonEncode(trimmed.map((e) => e.toJson()).toList());
    await p.setString(_itemsKey, jsonStr);
  }

  Future<void> addItems(List<FeedItem> newItems) async {
    final items = await getItems();
    
    // Remove duplicates based on URL
    final existingUrls = items.map((i) => i.url).toSet();
    final uniqueNew = newItems.where((i) => !existingUrls.contains(i.url));
    
    items.insertAll(0, uniqueNew);
    
    // Sort by published date descending
    items.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    
    await saveItems(items);
  }

  Future<void> markItemRead(String itemId) async {
    final items = await getItems();
    final index = items.indexWhere((i) => i.id == itemId);
    if (index >= 0) {
      items[index] = items[index].copyWith(isRead: true);
      await saveItems(items);
    }
  }

  // Bookmarks
  Future<List<Bookmark>> getBookmarks() async {
    final p = await prefs;
    final jsonStr = p.getString(_bookmarksKey);
    if (jsonStr == null) return [];

    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => Bookmark.fromJson(e)).toList();
  }

  Future<void> saveBookmarks(List<Bookmark> bookmarks) async {
    final p = await prefs;
    final jsonStr = jsonEncode(bookmarks.map((e) => e.toJson()).toList());
    await p.setString(_bookmarksKey, jsonStr);
  }

  Future<void> addBookmark(Bookmark bookmark) async {
    final bookmarks = await getBookmarks();
    
    // Check if already bookmarked
    if (bookmarks.any((b) => b.feedItemId == bookmark.feedItemId)) {
      return;
    }
    
    bookmarks.insert(0, bookmark);
    await saveBookmarks(bookmarks);
  }

  Future<void> removeBookmark(String bookmarkId) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.id == bookmarkId);
    await saveBookmarks(bookmarks);
  }

  Future<bool> isBookmarked(String feedItemId) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b.feedItemId == feedItemId);
  }

  // Filters
  Future<List<ContentFilter>> getFilters() async {
    final p = await prefs;
    final jsonStr = p.getString(_filtersKey);
    if (jsonStr == null) return [];

    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => ContentFilter.fromJson(e)).toList();
  }

  Future<void> saveFilters(List<ContentFilter> filters) async {
    final p = await prefs;
    final jsonStr = jsonEncode(filters.map((e) => e.toJson()).toList());
    await p.setString(_filtersKey, jsonStr);
  }

  Future<void> addFilter(ContentFilter filter) async {
    final filters = await getFilters();
    filters.add(filter);
    await saveFilters(filters);
  }

  Future<void> removeFilter(String filterId) async {
    final filters = await getFilters();
    filters.removeWhere((f) => f.id == filterId);
    await saveFilters(filters);
  }

  Future<void> toggleFilter(String filterId) async {
    final filters = await getFilters();
    final index = filters.indexWhere((f) => f.id == filterId);
    if (index >= 0) {
      filters[index] = filters[index].copyWith(
        isActive: !filters[index].isActive,
      );
      await saveFilters(filters);
    }
  }

  // Settings
  Future<Map<String, dynamic>> getSettings() async {
    final p = await prefs;
    final jsonStr = p.getString(_settingsKey);
    if (jsonStr == null) return {};
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final settings = await getSettings();
    settings[key] = value;
    final p = await prefs;
    await p.setString(_settingsKey, jsonEncode(settings));
  }

  // Clear all data
  Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
}
