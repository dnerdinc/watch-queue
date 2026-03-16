-- ═══════════════════════════════════════════════
-- THE WATCH QUEUE — Supabase Schema Setup
-- Run this in your Supabase SQL Editor
-- ═══════════════════════════════════════════════

-- 1. Profiles table (stores display names)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT 'anonymous',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 2. User films table (watched status, notes, ratings, custom films)
CREATE TABLE IF NOT EXISTS user_films (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  film_title TEXT NOT NULL,
  watched BOOLEAN DEFAULT FALSE,
  note TEXT DEFAULT '',
  rating INTEGER CHECK (rating >= 0 AND rating <= 5),
  emoji TEXT DEFAULT '🎬',
  is_custom BOOLEAN DEFAULT FALSE,
  summary TEXT DEFAULT '',
  poster_url TEXT DEFAULT '',
  yt TEXT DEFAULT '',
  tags JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, film_title)
);

-- Auto-update timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_user_films_updated_at ON user_films;
CREATE TRIGGER update_user_films_updated_at
  BEFORE UPDATE ON user_films
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 3. Activity feed (for the live "X just watched Y" feed)
CREATE TABLE IF NOT EXISTS activity_feed (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  display_name TEXT NOT NULL,
  film_title TEXT NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('watched', 'added', 'rated')),
  rating INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── ROW LEVEL SECURITY ─────────────────────────

-- Profiles: everyone can read, only own user can write
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles readable" ON profiles FOR SELECT USING (true);
CREATE POLICY "Own profile writable" ON profiles FOR ALL USING (auth.uid() = id);

-- User films: own rows only for write, but others can read watched status (for friends feed)
ALTER TABLE user_films ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Own films full access" ON user_films FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Friends can see watched films" ON user_films FOR SELECT USING (watched = true);

-- Activity feed: anyone logged in can read, own user inserts only
ALTER TABLE activity_feed ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Feed readable by all" ON activity_feed FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Own activity inserts" ON activity_feed FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ── REALTIME ───────────────────────────────────
-- Enable realtime for live activity updates
ALTER PUBLICATION supabase_realtime ADD TABLE user_films;
ALTER PUBLICATION supabase_realtime ADD TABLE activity_feed;
