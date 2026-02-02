class Bookmark {
  final String id;
  final String userId;
  final String feedItemId;
  final String title;
  final String url;
  final String? imageUrl;
  final String sourceName;
  final String? note;
  final List<String> tags;
  final DateTime createdAt;
  final bool isRead;

  Bookmark({
    required this.id,
    required this.userId,
    required this.feedItemId,
    required this.title,
    required this.url,
    this.imageUrl,
    required this.sourceName,
    this.note,
    this.tags = const [],
    required this.createdAt,
    this.isRead = false,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      feedItemId: json['feed_item_id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      imageUrl: json['image_url'] as String?,
      sourceName: json['source_name'] as String,
      note: json['note'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'feed_item_id': feedItemId,
      'title': title,
      'url': url,
      'image_url': imageUrl,
      'source_name': sourceName,
      'note': note,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  Bookmark copyWith({
    String? id,
    String? userId,
    String? feedItemId,
    String? title,
    String? url,
    String? imageUrl,
    String? sourceName,
    String? note,
    List<String>? tags,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return Bookmark(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      feedItemId: feedItemId ?? this.feedItemId,
      title: title ?? this.title,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceName: sourceName ?? this.sourceName,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
