enum FilterType {
  keyword,  // Block by keyword
  source,   // Block by source
  author,   // Block by author
}

enum FilterAction {
  hide,     // Completely hide matching items
  mute,     // Show grayed out / collapsed
}

class ContentFilter {
  final String id;
  final String userId;
  final FilterType type;
  final String value;
  final FilterAction action;
  final bool isActive;
  final DateTime createdAt;

  ContentFilter({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    this.action = FilterAction.hide,
    this.isActive = true,
    required this.createdAt,
  });

  factory ContentFilter.fromJson(Map<String, dynamic> json) {
    return ContentFilter(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: FilterType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FilterType.keyword,
      ),
      value: json['value'] as String,
      action: FilterAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => FilterAction.hide,
      ),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'value': value,
      'action': action.name,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ContentFilter copyWith({
    String? id,
    String? userId,
    FilterType? type,
    String? value,
    FilterAction? action,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ContentFilter(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      action: action ?? this.action,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if this filter matches the given feed item
  bool matches(String title, String? description, String sourceName, String? author) {
    final lowerValue = value.toLowerCase();
    
    switch (type) {
      case FilterType.keyword:
        final searchText = '$title ${description ?? ''}'.toLowerCase();
        return searchText.contains(lowerValue);
      case FilterType.source:
        return sourceName.toLowerCase().contains(lowerValue);
      case FilterType.author:
        return author?.toLowerCase().contains(lowerValue) ?? false;
    }
  }
}
