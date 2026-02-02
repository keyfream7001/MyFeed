/// Supabase configuration
/// Replace these with your actual Supabase project credentials
class SupabaseConfig {
  // TODO: Replace with your Supabase URL
  static const String url = 'https://your-project.supabase.co';

  // TODO: Replace with your Supabase anon key
  static const String anonKey = 'your-anon-key';

  // Database table names
  static const String feedSourcesTable = 'feed_sources';
  static const String feedItemsTable = 'feed_items';
  static const String bookmarksTable = 'bookmarks';
  static const String filtersTable = 'filters';
  static const String userSettingsTable = 'user_settings';
}
