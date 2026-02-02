import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/feed_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/filter_provider.dart';
import '../models/feed_item.dart';
import '../widgets/feed_card.dart';
import '../widgets/source_filter_chip.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ko', timeago.KoMessages());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MyFeed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<FeedProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: provider.isLoading
                    ? null
                    : () => provider.refreshAllFeeds(),
                tooltip: '새로고침',
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'mark_all_read') {
                context.read<FeedProvider>().markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모두 읽음 처리됨')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text('모두 읽음 처리'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer3<FeedProvider, BookmarkProvider, FilterProvider>(
        builder: (context, feedProvider, bookmarkProvider, filterProvider, _) {
          if (feedProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    feedProvider.error!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      feedProvider.clearError();
                      feedProvider.refreshAllFeeds();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          // Apply filters
          final filteredItems = filterProvider.applyFilters(feedProvider.items);

          if (feedProvider.sources.isEmpty) {
            return _buildEmptySourceState(context);
          }

          if (filteredItems.isEmpty && !feedProvider.isLoading) {
            return _buildEmptyFeedState(context, feedProvider);
          }

          return Column(
            children: [
              // Source filter chips
              if (feedProvider.sources.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      SourceFilterChip(
                        label: '전체',
                        isSelected: feedProvider.selectedSourceId == null,
                        onTap: () => feedProvider.filterBySource(null),
                      ),
                      const SizedBox(width: 8),
                      ...feedProvider.sources
                          .where((s) => s.isActive)
                          .map((source) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: SourceFilterChip(
                                  label: source.name,
                                  iconUrl: source.iconUrl,
                                  isSelected: feedProvider.selectedSourceId == source.id,
                                  onTap: () => feedProvider.filterBySource(source.id),
                                ),
                              )),
                    ],
                  ),
                ),
              
              // Feed list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => feedProvider.refreshAllFeeds(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isMuted = filterProvider.shouldMute(item);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FeedCard(
                          item: item,
                          isMuted: isMuted,
                          isBookmarked: bookmarkProvider.isBookmarked(item.id),
                          onTap: () => _openArticle(item, feedProvider),
                          onBookmark: () => bookmarkProvider.toggleBookmark(item),
                          onShare: () => _shareArticle(item),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptySourceState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rss_feed,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '피드를 추가해보세요!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '좋아하는 블로그, 뉴스 사이트의\nRSS 주소를 추가하면 여기서 볼 수 있어요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                // Navigate to sources tab (index 1)
                // This is handled by MainScreen
              },
              icon: const Icon(Icons.add),
              label: const Text('피드 추가하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeedState(BuildContext context, FeedProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '새 글이 없어요',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              '아래로 당겨서 새로고침 해보세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => provider.refreshAllFeeds(),
              icon: const Icon(Icons.refresh),
              label: const Text('새로고침'),
            ),
          ],
        ),
      ),
    );
  }

  void _openArticle(FeedItem item, FeedProvider provider) {
    provider.markAsRead(item.id);
    // TODO: Open in-app browser or external browser
    // For now, just mark as read
  }

  void _shareArticle(FeedItem item) {
    // TODO: Implement share
  }
}
