import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/filter_provider.dart';
import 'feed_screen.dart';
import 'sources_screen.dart';
import 'bookmarks_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isInitialized = false;

  final List<Widget> _screens = const [
    FeedScreen(),
    SourcesScreen(),
    BookmarksScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initProviders();
  }

  Future<void> _initProviders() async {
    if (_isInitialized) return;

    final feedProvider = context.read<FeedProvider>();
    final bookmarkProvider = context.read<BookmarkProvider>();
    final filterProvider = context.read<FilterProvider>();

    await Future.wait([
      feedProvider.init(),
      bookmarkProvider.init(),
      filterProvider.init(),
    ]);

    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: '피드',
          ),
          NavigationDestination(
            icon: const Icon(Icons.rss_feed_outlined),
            selectedIcon: const Icon(Icons.rss_feed),
            label: '소스',
          ),
          NavigationDestination(
            icon: Consumer<BookmarkProvider>(
              builder: (context, provider, child) {
                final count = provider.unreadCount;
                return Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.bookmark_outline),
                );
              },
            ),
            selectedIcon: const Icon(Icons.bookmark),
            label: '저장',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
