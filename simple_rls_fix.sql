-- Simple RLS Fix using DEFAULT values
-- Run this in your Supabase SQL Editor

-- Step 1: Drop all existing policies
DROP POLICY IF EXISTS "Users can insert their own posts" ON posts;
DROP POLICY IF EXISTS "Posts are viewable by everyone" ON posts;
DROP POLICY IF EXISTS "Users can update their own posts" ON posts;
DROP POLICY IF EXISTS "Users can delete their own posts" ON posts;
DROP POLICY IF EXISTS "Authenticated users can create posts" ON posts;
DROP POLICY IF EXISTS "Everyone can view posts" ON posts;
DROP POLICY IF EXISTS "Users can create posts" ON posts;
DROP POLICY IF EXISTS "Posts are publicly viewable" ON posts;
DROP POLICY IF EXISTS "Users can modify their posts" ON posts;
DROP POLICY IF EXISTS "Users can delete their posts" ON posts;
DROP POLICY IF EXISTS "posts_insert_policy" ON posts;
DROP POLICY IF EXISTS "posts_select_policy" ON posts;
DROP POLICY IF EXISTS "posts_update_policy" ON posts;
DROP POLICY IF EXISTS "posts_delete_policy" ON posts;

-- Step 2: Set DEFAULT values for user_id columns (makes RLS much easier)
ALTER TABLE posts ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE comments ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE likes ALTER COLUMN user_id SET DEFAULT auth.uid();

-- Step 3: Ensure all users have profiles
INSERT INTO profiles (id, username, avatar_url, updated_at)
SELECT 
    au.id,
    COALESCE(au.raw_user_meta_data->>'username', split_part(au.email, '@', 1), 'user') as username,
    null as avatar_url,
    now() as updated_at
FROM auth.users au
WHERE au.id NOT IN (SELECT p.id FROM profiles p WHERE p.id IS NOT NULL)
ON CONFLICT (id) DO NOTHING;

-- Step 4: Enable RLS and create SIMPLE policies
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Simple policies for posts
CREATE POLICY "anyone_can_view_posts" ON posts FOR SELECT USING (true);
CREATE POLICY "authenticated_can_insert_posts" ON posts FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "users_can_update_own_posts" ON posts FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "users_can_delete_own_posts" ON posts FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Enable RLS for other tables
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anyone_can_view_comments" ON comments FOR SELECT USING (true);
CREATE POLICY "authenticated_can_insert_comments" ON comments FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "users_can_update_own_comments" ON comments FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "users_can_delete_own_comments" ON comments FOR DELETE TO authenticated USING (auth.uid() = user_id);

ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anyone_can_view_likes" ON likes FOR SELECT USING (true);
CREATE POLICY "authenticated_can_insert_likes" ON likes FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "users_can_delete_own_likes" ON likes FOR DELETE TO authenticated USING (auth.uid() = user_id);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anyone_can_view_profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "users_can_insert_own_profile" ON profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "users_can_update_own_profile" ON profiles FOR UPDATE TO authenticated USING (auth.uid() = id);