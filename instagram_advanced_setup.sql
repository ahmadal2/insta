-- Advanced Instagram-Clone Database Setup
-- Complete setup with Followers, Reposts, and RLS Policies

-- Step 1: Drop all existing policies
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename IN ('posts', 'likes', 'comments', 'profiles', 'follows', 'reposts')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
            r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;

-- Step 2: Disable RLS temporarily
ALTER TABLE IF EXISTS posts DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS likes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS comments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS follows DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS reposts DISABLE ROW LEVEL SECURITY;

-- Step 3: Create/Update all tables
-- Profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text,
  avatar_url text,
  bio text,
  updated_at timestamp with time zone default now()
);

-- Posts table
CREATE TABLE IF NOT EXISTS posts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  image_url text not null,
  caption text,
  created_at timestamp with time zone default now()
);

-- Likes table
CREATE TABLE IF NOT EXISTS likes (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid references posts(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  created_at timestamp with time zone default now(),
  unique (post_id, user_id)
);

-- Comments table
CREATE TABLE IF NOT EXISTS comments (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid references posts(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  text text not null,
  created_at timestamp with time zone default now()
);

-- Follows table (NEW)
CREATE TABLE IF NOT EXISTS follows (
  follower_id uuid references auth.users(id) on delete cascade not null,
  following_id uuid references auth.users(id) on delete cascade not null,
  created_at timestamp with time zone default now(),
  primary key (follower_id, following_id),
  check (follower_id != following_id)
);

-- Reposts table (NEW)
CREATE TABLE IF NOT EXISTS reposts (
  id uuid primary key default uuid_generate_v4(),
  original_post_id uuid references posts(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  created_at timestamp with time zone default now(),
  unique (original_post_id, user_id)
);

-- Step 4: Initialize profiles for all users
INSERT INTO profiles (id, username, avatar_url, updated_at)
SELECT
    au.id,
    COALESCE(
        au.raw_user_meta_data->>'username', 
        split_part(au.email, '@', 1), 
        'user'
    ) as username,
    null as avatar_url,
    now() as updated_at
FROM auth.users au
WHERE au.id NOT IN (SELECT p.id FROM profiles p WHERE p.id IS NOT NULL)
ON CONFLICT (id) DO NOTHING;

-- Step 5: Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE reposts ENABLE ROW LEVEL SECURITY;

-- Step 6: Create comprehensive RLS policies

-- PROFILES POLICIES
-- Everyone can view profiles (public feed)
CREATE POLICY "Profiles are viewable by everyone" ON profiles
FOR SELECT TO authenticated, anon
USING (true);

-- Only user can manage their own profile
CREATE POLICY "Users can manage their own profile" ON profiles
FOR ALL TO authenticated
USING ((SELECT auth.uid()) = id)
WITH CHECK ((SELECT auth.uid()) = id);

-- POSTS POLICIES
-- Authenticated users can create posts
CREATE POLICY "Users can create posts" ON posts
FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

-- Posts are publicly viewable
CREATE POLICY "Posts are publicly viewable" ON posts
FOR SELECT TO authenticated, anon
USING (true);

-- Users can only modify their own posts
CREATE POLICY "Users can modify their posts" ON posts
FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

-- Users can only delete their own posts
CREATE POLICY "Users can delete their posts" ON posts
FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- COMMENTS POLICIES
-- Authenticated users can create comments
CREATE POLICY "Users can create comments" ON comments
FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

-- Comments are publicly viewable
CREATE POLICY "Comments are publicly viewable" ON comments
FOR SELECT TO authenticated, anon
USING (true);

-- Users can only modify their own comments
CREATE POLICY "Users can modify their comments" ON comments
FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

-- Users can only delete their own comments
CREATE POLICY "Users can delete their comments" ON comments
FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- LIKES POLICIES
-- Authenticated users can create likes
CREATE POLICY "Users can create likes" ON likes
FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

-- Likes are viewable by everyone
CREATE POLICY "Likes are viewable" ON likes
FOR SELECT TO authenticated, anon
USING (true);

-- Users can only delete their own likes
CREATE POLICY "Users can delete their likes" ON likes
FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- FOLLOWS POLICIES (NEW)
-- Authenticated users can follow others
CREATE POLICY "Users can follow others" ON follows
FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = follower_id);

-- Follow relationships are publicly viewable
CREATE POLICY "Follows are viewable" ON follows
FOR SELECT TO authenticated, anon
USING (true);

-- Users can only unfollow their own follows
CREATE POLICY "Users can delete their follows" ON follows
FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = follower_id);

-- REPOSTS POLICIES (NEW)
-- Authenticated users can create reposts
CREATE POLICY "Users can create reposts" ON reposts
FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

-- Reposts are publicly viewable
CREATE POLICY "Reposts are viewable" ON reposts
FOR SELECT TO authenticated, anon
USING (true);

-- Users can only delete their own reposts
CREATE POLICY "Users can delete their reposts" ON reposts
FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- Step 7: Create helpful views for complex queries
-- View for posts with engagement stats
CREATE OR REPLACE VIEW posts_with_stats AS
SELECT 
    p.*,
    pr.username,
    pr.avatar_url,
    (SELECT COUNT(*) FROM likes l WHERE l.post_id = p.id) as likes_count,
    (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.id) as comments_count,
    (SELECT COUNT(*) FROM reposts r WHERE r.original_post_id = p.id) as reposts_count
FROM posts p
LEFT JOIN profiles pr ON p.user_id = pr.id;

-- View for user stats
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    p.*,
    (SELECT COUNT(*) FROM posts po WHERE po.user_id = p.id) as posts_count,
    (SELECT COUNT(*) FROM follows f WHERE f.following_id = p.id) as followers_count,
    (SELECT COUNT(*) FROM follows f WHERE f.follower_id = p.id) as following_count
FROM profiles p;

-- Step 8: Verification
SELECT 'Advanced Instagram-Clone Database Setup Complete!' as status;

-- Show all policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('posts', 'profiles', 'likes', 'comments', 'follows', 'reposts')
ORDER BY tablename, policyname;