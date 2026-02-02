import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/feed_provider.dart';
import '../models/feed_source.dart';
import '../widgets/add_feed_dialog.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '피드 소스',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<FeedProvider>(
        builder: (context, provider, _) {
          if (provider.sources.isEmpty) {
            return _buildEmptyState(context);
          }

          // Group sources by category
          final grouped = <String, List<FeedSource>>{};
          for (final source in provider.sources) {
            final category = source.category ?? '기타';
            grouped.putIfAbsent(category, () => []).add(source);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final category = grouped.keys.elementAt(index);
              final sources = grouped[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...sources.map((source) => _buildSourceTile(context, source, provider)),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFeedDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('피드 추가'),
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
              Icons.add_circle_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '구독 중인 피드가 없어요',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'RSS 피드 주소를 추가해서\n원하는 콘텐츠만 모아보세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showAddFeedDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('첫 피드 추가하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTile(BuildContext context, FeedSource source, FeedProvider provider) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _confirmDelete(context, source, provider),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '삭제',
          ),
        ],
      ),
      child: ListTile(
        leading: _buildSourceIcon(source),
        title: Text(
          source.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: source.isActive
                ? null
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        subtitle: Text(
          source.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        trailing: Switch(
          value: source.isActive,
          onChanged: (_) => provider.toggleSourceActive(source.id),
        ),
        onTap: () => _showSourceDetails(context, source),
      ),
    );
  }

  Widget _buildSourceIcon(FeedSource source) {
    if (source.iconUrl != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(source.iconUrl!),
        onBackgroundImageError: (_, __) {},
        child: source.iconUrl == null
            ? Text(source.name[0].toUpperCase())
            : null,
      );
    }

    return CircleAvatar(
      child: Text(source.name[0].toUpperCase()),
    );
  }

  void _showAddFeedDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AddFeedDialog(),
    );
  }

  void _showSourceDetails(BuildContext context, FeedSource source) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSourceIcon(source),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        source.type.name.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(context, '피드 URL', source.url),
            if (source.category != null)
              _buildDetailRow(context, '카테고리', source.category!),
            _buildDetailRow(
              context,
              '추가된 날짜',
              _formatDate(source.createdAt),
            ),
            if (source.lastFetchedAt != null)
              _buildDetailRow(
                context,
                '마지막 업데이트',
                _formatDate(source.lastFetchedAt!),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void _confirmDelete(BuildContext context, FeedSource source, FeedProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('피드 삭제'),
        content: Text('\'${source.name}\'을(를) 삭제하시겠습니까?\n해당 피드의 모든 글도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              provider.removeSource(source.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('\'${source.name}\' 삭제됨')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
