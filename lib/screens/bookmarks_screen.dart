import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/bookmark_provider.dart';
import '../models/bookmark.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '저장한 글',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<BookmarkProvider>(
            builder: (context, provider, _) {
              if (provider.bookmarks.isEmpty) return const SizedBox();
              
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'clear_read') {
                    _clearReadBookmarks(context, provider);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear_read',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep),
                        SizedBox(width: 8),
                        Text('읽은 글 정리'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, provider, _) {
          if (provider.bookmarks.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = provider.bookmarks[index];
              return _buildBookmarkTile(context, bookmark, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '저장한 글이 없어요',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              '피드에서 관심있는 글을\n북마크해보세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkTile(BuildContext context, Bookmark bookmark, BookmarkProvider provider) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => provider.removeBookmark(bookmark.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '삭제',
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: bookmark.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  bookmark.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.article,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.article,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
        title: Text(
          bookmark.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: bookmark.isRead
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                bookmark.sourceName,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeago.format(bookmark.createdAt, locale: 'ko'),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        trailing: bookmark.isRead
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                size: 20,
              )
            : null,
        onTap: () => _openBookmark(context, bookmark, provider),
        onLongPress: () => _showBookmarkOptions(context, bookmark, provider),
      ),
    );
  }

  Future<void> _openBookmark(BuildContext context, Bookmark bookmark, BookmarkProvider provider) async {
    provider.markAsRead(bookmark.id);
    
    final uri = Uri.parse(bookmark.url);
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

  void _showBookmarkOptions(BuildContext context, Bookmark bookmark, BookmarkProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: const Text('브라우저에서 열기'),
              onTap: () {
                Navigator.pop(context);
                _openBookmark(context, bookmark, provider);
              },
            ),
            ListTile(
              leading: Icon(
                bookmark.isRead ? Icons.mark_email_unread : Icons.done,
              ),
              title: Text(bookmark.isRead ? '읽지 않음으로 표시' : '읽음으로 표시'),
              onTap: () {
                Navigator.pop(context);
                // Toggle read status (need to implement in provider)
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                provider.removeBookmark(bookmark.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clearReadBookmarks(BuildContext context, BookmarkProvider provider) {
    final readCount = provider.bookmarks.where((b) => b.isRead).length;
    
    if (readCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('읽은 글이 없습니다')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('읽은 글 정리'),
        content: Text('읽은 글 $readCount개를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              // Remove all read bookmarks
              final toRemove = provider.bookmarks
                  .where((b) => b.isRead)
                  .map((b) => b.id)
                  .toList();
              for (final id in toRemove) {
                provider.removeBookmark(id);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$readCount개의 글이 삭제되었습니다')),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
