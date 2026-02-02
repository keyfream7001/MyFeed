import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
import 'package:html/parser.dart' as html_parser;
import '../models/feed_item.dart';
import '../models/feed_source.dart';

class FeedService {
  static final FeedService _instance = FeedService._internal();
  factory FeedService() => _instance;
  FeedService._internal();

  /// Fetch and parse RSS/Atom feed from URL
  Future<List<FeedItem>> fetchFeed(FeedSource source) async {
    try {
      final response = await http.get(
        Uri.parse(source.url),
        headers: {
          'User-Agent': 'MyFeed/1.0 (RSS Reader)',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch feed: ${response.statusCode}');
      }

      final body = response.body;
      
      // Try parsing as RSS first, then Atom
      try {
        final rssFeed = RssFeed.parse(body);
        return _parseRssFeed(rssFeed, source);
      } catch (_) {
        try {
          final atomFeed = AtomFeed.parse(body);
          return _parseAtomFeed(atomFeed, source);
        } catch (_) {
          throw Exception('Unable to parse feed format');
        }
      }
    } catch (e) {
      throw Exception('Error fetching feed: $e');
    }
  }

  List<FeedItem> _parseRssFeed(RssFeed feed, FeedSource source) {
    final items = <FeedItem>[];
    final now = DateTime.now();

    for (final item in feed.items ?? []) {
      items.add(FeedItem(
        id: _generateId(item.link ?? item.title ?? ''),
        sourceId: source.id,
        sourceName: source.name,
        sourceIconUrl: source.iconUrl ?? feed.image?.url,
        title: _cleanHtml(item.title ?? 'No Title'),
        description: _cleanHtml(item.description ?? ''),
        content: item.content?.value,
        url: item.link ?? '',
        imageUrl: _extractImageUrl(item),
        author: item.author ?? item.dc?.creator,
        publishedAt: item.pubDate ?? now,
        fetchedAt: now,
      ));
    }

    return items;
  }

  List<FeedItem> _parseAtomFeed(AtomFeed feed, FeedSource source) {
    final items = <FeedItem>[];
    final now = DateTime.now();

    for (final item in feed.items ?? []) {
      final link = item.links?.isNotEmpty == true
          ? item.links!.first.href
          : null;

      items.add(FeedItem(
        id: _generateId(link ?? item.title ?? ''),
        sourceId: source.id,
        sourceName: source.name,
        sourceIconUrl: source.iconUrl ?? feed.icon,
        title: _cleanHtml(item.title ?? 'No Title'),
        description: _cleanHtml(item.summary ?? ''),
        content: item.content,
        url: link ?? '',
        imageUrl: _extractAtomImageUrl(item),
        author: item.authors?.isNotEmpty == true
            ? item.authors!.first.name
            : null,
        publishedAt: item.published ?? item.updated ?? now,
        fetchedAt: now,
      ));
    }

    return items;
  }

  String _generateId(String input) {
    return input.hashCode.toRadixString(16);
  }

  String _cleanHtml(String html) {
    final document = html_parser.parse(html);
    return document.body?.text ?? html;
  }

  String? _extractImageUrl(RssItem item) {
    // Check enclosure
    if (item.enclosure?.url != null &&
        item.enclosure!.type?.startsWith('image/') == true) {
      return item.enclosure!.url;
    }
    
    // Check media content
    if (item.media?.contents?.isNotEmpty == true) {
      final media = item.media!.contents!.first;
      if (media.medium == 'image' || media.type?.startsWith('image/') == true) {
        return media.url;
      }
    }

    // Try to extract from description
    final imgMatch = RegExp(r'<img[^>]+src="([^"]+)"').firstMatch(
      item.description ?? '',
    );
    return imgMatch?.group(1);
  }

  String? _extractAtomImageUrl(AtomItem item) {
    // Check media
    if (item.media?.contents?.isNotEmpty == true) {
      return item.media!.contents!.first.url;
    }

    // Try to extract from content
    final imgMatch = RegExp(r'<img[^>]+src="([^"]+)"').firstMatch(
      item.content ?? item.summary ?? '',
    );
    return imgMatch?.group(1);
  }

  /// Validate if a URL is a valid RSS/Atom feed
  Future<FeedValidationResult> validateFeedUrl(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'MyFeed/1.0 (RSS Reader)',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return FeedValidationResult(
          isValid: false,
          error: 'HTTP ${response.statusCode}',
        );
      }

      String? feedTitle;
      String? feedIcon;

      try {
        final rssFeed = RssFeed.parse(response.body);
        feedTitle = rssFeed.title;
        feedIcon = rssFeed.image?.url;
      } catch (_) {
        try {
          final atomFeed = AtomFeed.parse(response.body);
          feedTitle = atomFeed.title;
          feedIcon = atomFeed.icon;
        } catch (_) {
          return FeedValidationResult(
            isValid: false,
            error: 'Not a valid RSS/Atom feed',
          );
        }
      }

      return FeedValidationResult(
        isValid: true,
        feedTitle: feedTitle,
        feedIcon: feedIcon,
      );
    } catch (e) {
      return FeedValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }
}

class FeedValidationResult {
  final bool isValid;
  final String? feedTitle;
  final String? feedIcon;
  final String? error;

  FeedValidationResult({
    required this.isValid,
    this.feedTitle,
    this.feedIcon,
    this.error,
  });
}
