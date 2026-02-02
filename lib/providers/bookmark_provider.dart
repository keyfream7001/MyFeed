import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/bookmark.dart';
import '../models/feed_item.dart';
import '../services/storage_service.dart';

class BookmarkProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  List<Bookmark> _bookmarks = [];
  bool _isLoading = false;
  String? _error;

  List<Bookmark> get bookmarks => _bookmarks;
  List<Bookmark> get unreadBookmarks => _bookmarks.where((b) => !b.isRead).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _bookmarks.length;
  int get unreadCount => unreadBookmarks.length;

  /// Initialize and load bookmarks from storage
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _bookmarks = await _storage.getBookmarks();
      _error = null;
    } catch (e) {
      _error = 'Failed to load bookmarks: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a feed item to bookmarks
  Future<bool> addBookmark(FeedItem item, {String? note, List<String>? tags}) async {
    try {
      // Check if already bookmarked
      if (isBookmarked(item.id)) {
        return false;
      }

      final bookmark = Bookmark(
        id: _uuid.v4(),
        userId: 'local_user',
        feedItemId: item.id,
        title: item.title,
        url: item.url,
        imageUrl: item.imageUrl,
        sourceName: item.sourceName,
        note: note,
        tags: tags ?? [],
        createdAt: DateTime.now(),
      );

      await _storage.addBookmark(bookmark);
      _bookmarks.insert(0, bookmark);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add bookmark: $e';
      notifyListeners();
      return false;
    }
  }

  /// Remove a bookmark
  Future<void> removeBookmark(String bookmarkId) async {
    try {
      await _storage.removeBookmark(bookmarkId);
      _bookmarks.removeWhere((b) => b.id == bookmarkId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove bookmark: $e';
      notifyListeners();
    }
  }

  /// Remove bookmark by feed item ID
  Future<void> removeByFeedItemId(String feedItemId) async {
    final bookmark = _bookmarks.firstWhere(
      (b) => b.feedItemId == feedItemId,
      orElse: () => throw Exception('Bookmark not found'),
    );
    await removeBookmark(bookmark.id);
  }

  /// Check if an item is bookmarked
  bool isBookmarked(String feedItemId) {
    return _bookmarks.any((b) => b.feedItemId == feedItemId);
  }

  /// Toggle bookmark
  Future<void> toggleBookmark(FeedItem item) async {
    if (isBookmarked(item.id)) {
      await removeByFeedItemId(item.id);
    } else {
      await addBookmark(item);
    }
  }

  /// Mark bookmark as read
  Future<void> markAsRead(String bookmarkId) async {
    final index = _bookmarks.indexWhere((b) => b.id == bookmarkId);
    if (index >= 0) {
      _bookmarks[index] = _bookmarks[index].copyWith(isRead: true);
      await _storage.saveBookmarks(_bookmarks);
      notifyListeners();
    }
  }

  /// Update bookmark note
  Future<void> updateNote(String bookmarkId, String note) async {
    final index = _bookmarks.indexWhere((b) => b.id == bookmarkId);
    if (index >= 0) {
      _bookmarks[index] = _bookmarks[index].copyWith(note: note);
      await _storage.saveBookmarks(_bookmarks);
      notifyListeners();
    }
  }

  /// Update bookmark tags
  Future<void> updateTags(String bookmarkId, List<String> tags) async {
    final index = _bookmarks.indexWhere((b) => b.id == bookmarkId);
    if (index >= 0) {
      _bookmarks[index] = _bookmarks[index].copyWith(tags: tags);
      await _storage.saveBookmarks(_bookmarks);
      notifyListeners();
    }
  }

  /// Get bookmarks by tag
  List<Bookmark> getByTag(String tag) {
    return _bookmarks.where((b) => b.tags.contains(tag)).toList();
  }

  /// Get all unique tags
  List<String> getAllTags() {
    final tags = <String>{};
    for (final bookmark in _bookmarks) {
      tags.addAll(bookmark.tags);
    }
    return tags.toList()..sort();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
