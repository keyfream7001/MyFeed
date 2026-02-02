class FeedItem {
  final String id;
  final String sourceId;
  final String sourceName;
  final String? sourceIconUrl;
  final String title;
  final String? description;
  final String? content;
  final String url;
  final String? imageUrl;
  final String? author;
  final DateTime publishedAt;
  final DateTime fetchedAt;
  final bool isRead;
  final bool isBookmarked;

  FeedItem({
    required this.id,
    required this.sourceId,
    required this.sourceName,
    this.sourceIconUrl,
    required this.title,
    this.description,
    this.content,
    required this.url,
    this.imageUrl,
    this.author,
    required this.publishedAt,
    required this.fetchedAt,
    this.isRead = false,
    this.isBookmarked = false,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] as String,
      sourceId: json['source_id'] as String,
      sourceName: json['source_name'] as String? ?? 'Unknown',
      sourceIconUrl: json['source_icon_url'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      content: json['content'] as String?,
      url: json['url'] as String,
      imageUrl: json['image_url'] as String?,
      author: json['author'] as String?,
      publishedAt: DateTime.parse(json['published_at'] as String),
      fetchedAt: DateTime.parse(json['fetched_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_id': sourceId,
      'source_name': sourceName,
      'source_icon_url': sourceIconUrl,
      'title': title,
      'description': description,
      'content': content,
      'url': url,
      'image_url': imageUrl,
      'author': author,
      'published_at': publishedAt.toIso8601String(),
      'fetched_at': fetchedAt.toIso8601String(),
      'is_read': isRead,
      'is_bookmarked': isBookmarked,
    };
  }

  FeedItem copyWith({
    String? id,
    String? sourceId,
    String? sourceName,
    String? sourceIconUrl,
    String? title,
    String? description,
    String? content,
    String? url,
    String? imageUrl,
    String? author,
    DateTime? publishedAt,
    DateTime? fetchedAt,
    bool? isRead,
    bool? isBookmarked,
  }) {
    return FeedItem(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      sourceIconUrl: sourceIconUrl ?? this.sourceIconUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      publishedAt: publishedAt ?? this.publishedAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      isRead: isRead ?? this.isRead,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
