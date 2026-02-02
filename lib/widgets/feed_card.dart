import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_item.dart';

class FeedCard extends StatelessWidget {
  final FeedItem item;
  final bool isMuted;
  final bool isBookmarked;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;

  const FeedCard({
    super.key,
    required this.item,
    this.isMuted = false,
    this.isBookmarked = false,
    this.onTap,
    this.onBookmark,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = isMuted ? 0.5 : (item.isRead ? 0.7 : 1.0);

    return Opacity(
      opacity: opacity,
      child: Card(
        color: theme.colorScheme.surface,
        child: InkWell(
          onTap: () => _openArticle(context),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (item.imageUrl != null) _buildImage(context),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source and time
                    Row(
                      children: [
                        if (item.sourceIconUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: item.sourceIconUrl!,
                              width: 20,
                              height: 20,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const SizedBox(),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          item.sourceName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '·',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeago.format(item.publishedAt, locale: 'ko'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const Spacer(),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Title
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Description
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Author
                    if (item.author != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.author!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Actions
                    Row(
                      children: [
                        _buildActionButton(
                          context,
                          icon: isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_outline,
                          label: isBookmarked ? '저장됨' : '저장',
                          isActive: isBookmarked,
                          onTap: onBookmark,
                        ),
                        const SizedBox(width: 16),
                        _buildActionButton(
                          context,
                          icon: Icons.share_outlined,
                          label: '공유',
                          onTap: onShare,
                        ),
                        const Spacer(),
                        _buildActionButton(
                          context,
                          icon: Icons.open_in_new,
                          label: '열기',
                          onTap: () => _openArticle(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: CachedNetworkImage(
        imageUrl: item.imageUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 180,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => const SizedBox(),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openArticle(BuildContext context) async {
    onTap?.call();
    
    final uri = Uri.parse(item.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다')),
        );
      }
    }
  }
}
