enum FeedSourceType {
  rss,
  newsletter,
  custom,
}

class FeedSource {
  final String id;
  final String userId;
  final String name;
  final String url;
  final FeedSourceType type;
  final String? iconUrl;
  final String? category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastFetchedAt;

  FeedSource({
    required this.id,
    required this.userId,
    required this.name,
    required this.url,
    required this.type,
    this.iconUrl,
    this.category,
    this.isActive = true,
    required this.createdAt,
    this.lastFetchedAt,
  });

  factory FeedSource.fromJson(Map<String, dynamic> json) {
    return FeedSource(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      type: FeedSourceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FeedSourceType.rss,
      ),
      iconUrl: json['icon_url'] as String?,
      category: json['category'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastFetchedAt: json['last_fetched_at'] != null
          ? DateTime.parse(json['last_fetched_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'url': url,
      'type': type.name,
      'icon_url': iconUrl,
      'category': category,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_fetched_at': lastFetchedAt?.toIso8601String(),
    };
  }

  FeedSource copyWith({
    String? id,
    String? userId,
    String? name,
    String? url,
    FeedSourceType? type,
    String? iconUrl,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastFetchedAt,
  }) {
    return FeedSource(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      iconUrl: iconUrl ?? this.iconUrl,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }
}
