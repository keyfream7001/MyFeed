import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/filter_provider.dart';
import '../models/filter.dart';
import '../widgets/add_filter_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, '콘텐츠 필터'),
          _buildFilterSection(context),
          const Divider(),
          _buildSectionHeader(context, '앱 설정'),
          _buildAppSettingsSection(context),
          const Divider(),
          _buildSectionHeader(context, '정보'),
          _buildInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Consumer<FilterProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text('키워드 필터'),
              subtitle: Text('${provider.activeCount}개 활성화됨'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showFilterManagement(context),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('필터 추가'),
              onTap: () => _showAddFilterDialog(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppSettingsSection(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode),
          title: const Text('다크 모드'),
          subtitle: const Text('시스템 설정 따르기'),
          value: false,
          onChanged: null, // TODO: Implement theme switching
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('알림 설정'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Implement notification settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('준비 중인 기능입니다')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.telegram),
          title: const Text('텔레그램 브리핑'),
          subtitle: const Text('매일 아침 요약 받기'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Implement Telegram integration
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('준비 중인 기능입니다')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('앱 정보'),
          subtitle: const Text('MyFeed v1.0.0'),
          onTap: () => _showAboutDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('모든 데이터 삭제', style: TextStyle(color: Colors.red)),
          onTap: () => _confirmClearData(context),
        ),
      ],
    );
  }

  void _showFilterManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FilterManagementScreen(),
      ),
    );
  }

  void _showAddFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AddFilterDialog(),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'MyFeed',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.rss_feed,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text(
          '알고리즘 없이 내가 선택한 콘텐츠만, 시간순으로 보는 피드 앱',
        ),
      ],
    );
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 삭제'),
        content: const Text(
          '모든 피드 소스, 저장된 글, 필터 설정이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement clear all data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('모든 데이터가 삭제되었습니다')),
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

class FilterManagementScreen extends StatelessWidget {
  const FilterManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('필터 관리'),
      ),
      body: Consumer<FilterProvider>(
        builder: (context, provider, _) {
          if (provider.filters.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.filter_list_off,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '설정된 필터가 없어요',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '보기 싫은 키워드나 소스를\n필터에 추가해보세요',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.filters.length,
            itemBuilder: (context, index) {
              final filter = provider.filters[index];
              return _buildFilterTile(context, filter, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFilterDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterTile(BuildContext context, ContentFilter filter, FilterProvider provider) {
    final typeIcon = switch (filter.type) {
      FilterType.keyword => Icons.text_fields,
      FilterType.source => Icons.rss_feed,
      FilterType.author => Icons.person,
    };

    final typeLabel = switch (filter.type) {
      FilterType.keyword => '키워드',
      FilterType.source => '소스',
      FilterType.author => '작성자',
    };

    return ListTile(
      leading: Icon(typeIcon),
      title: Text(filter.value),
      subtitle: Text('$typeLabel · ${filter.action == FilterAction.hide ? '숨기기' : '흐리게'}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: filter.isActive,
            onChanged: (_) => provider.toggleFilter(filter.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, filter, provider),
          ),
        ],
      ),
    );
  }

  void _showAddFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AddFilterDialog(),
    );
  }

  void _confirmDelete(BuildContext context, ContentFilter filter, FilterProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('필터 삭제'),
        content: Text('\'${filter.value}\' 필터를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              provider.removeFilter(filter.id);
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
