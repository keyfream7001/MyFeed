-- MyFeed Supabase Schema
-- 알고리즘 없이 사용자가 직접 고른 소스만 보는 피드 앱

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- 1. Feed Sources (피드 소스)
-- =============================================
CREATE TABLE feed_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    url TEXT NOT NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'rss', -- rss, newsletter, custom
    icon_url TEXT,
    category VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_fetched_at TIMESTAMPTZ,
    
    UNIQUE(user_id, url)
);

-- Index for faster queries
CREATE INDEX idx_feed_sources_user_id ON feed_sources(user_id);
CREATE INDEX idx_feed_sources_is_active ON feed_sources(is_active);

-- RLS (Row Level Security)
ALTER TABLE feed_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own sources" ON feed_sources
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sources" ON feed_sources
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sources" ON feed_sources
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own sources" ON feed_sources
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- 2. Feed Items (피드 아이템)
-- =============================================
CREATE TABLE feed_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_id UUID NOT NULL REFERENCES feed_sources(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    content TEXT,
    url TEXT NOT NULL,
    image_url TEXT,
    author VARCHAR(255),
    published_at TIMESTAMPTZ NOT NULL,
    fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_read BOOLEAN NOT NULL DEFAULT false,
    
    UNIQUE(user_id, url) -- Prevent duplicates per user
);

-- Indexes for common queries
CREATE INDEX idx_feed_items_user_id ON feed_items(user_id);
CREATE INDEX idx_feed_items_source_id ON feed_items(source_id);
CREATE INDEX idx_feed_items_published_at ON feed_items(published_at DESC);
CREATE INDEX idx_feed_items_is_read ON feed_items(is_read);

-- RLS
ALTER TABLE feed_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own items" ON feed_items
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own items" ON feed_items
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own items" ON feed_items
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own items" ON feed_items
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- 3. Bookmarks (북마크)
-- =============================================
CREATE TABLE bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    feed_item_id UUID NOT NULL REFERENCES feed_items(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    image_url TEXT,
    source_name VARCHAR(255) NOT NULL,
    note TEXT,
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_read BOOLEAN NOT NULL DEFAULT false,
    
    UNIQUE(user_id, feed_item_id)
);

-- Indexes
CREATE INDEX idx_bookmarks_user_id ON bookmarks(user_id);
CREATE INDEX idx_bookmarks_created_at ON bookmarks(created_at DESC);
CREATE INDEX idx_bookmarks_tags ON bookmarks USING GIN(tags);

-- RLS
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own bookmarks" ON bookmarks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own bookmarks" ON bookmarks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own bookmarks" ON bookmarks
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own bookmarks" ON bookmarks
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- 4. Filters (필터)
-- =============================================
CREATE TABLE filters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- keyword, source, author
    value TEXT NOT NULL,
    action VARCHAR(50) NOT NULL DEFAULT 'hide', -- hide, mute
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(user_id, type, value)
);

-- Indexes
CREATE INDEX idx_filters_user_id ON filters(user_id);
CREATE INDEX idx_filters_is_active ON filters(is_active);

-- RLS
ALTER TABLE filters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own filters" ON filters
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own filters" ON filters
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own filters" ON filters
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own filters" ON filters
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- 5. User Settings (사용자 설정)
-- =============================================
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Telegram settings
    telegram_chat_id VARCHAR(100),
    telegram_enabled BOOLEAN NOT NULL DEFAULT false,
    briefing_time TIME DEFAULT '08:00:00',
    briefing_timezone VARCHAR(50) DEFAULT 'Asia/Seoul',
    
    -- App preferences
    theme VARCHAR(20) DEFAULT 'system', -- light, dark, system
    default_view VARCHAR(20) DEFAULT 'all', -- all, unread
    items_per_page INTEGER DEFAULT 50,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own settings" ON user_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own settings" ON user_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own settings" ON user_settings
    FOR UPDATE USING (auth.uid() = user_id);

-- =============================================
-- Functions & Triggers
-- =============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON user_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to clean old feed items (keep last 30 days)
CREATE OR REPLACE FUNCTION clean_old_feed_items()
RETURNS void AS $$
BEGIN
    DELETE FROM feed_items
    WHERE fetched_at < NOW() - INTERVAL '30 days'
    AND is_read = true
    AND id NOT IN (SELECT feed_item_id FROM bookmarks);
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Initial Data / Default Feeds (Optional)
-- =============================================
-- These can be added as "suggested feeds" in the app UI
-- Example popular Korean RSS feeds:
-- GeekNews: https://news.hada.io/rss
-- 44bits: https://www.44bits.io/ko/feed
