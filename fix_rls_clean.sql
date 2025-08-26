-- Clean RLS Policy Setup for AhmadInsta
-- Run this in your Supabase SQL Editor

-- Drop ALL existing policies completely
DROP POLICY IF EXISTS "Users can insert their own posts" ON posts;
DROP POLICY IF EXISTS "Posts are viewable by everyone" ON posts;
DROP POLICY IF EXISTS "Users can update their own posts" ON posts;
DROP POLICY IF EXISTS "Users can delete their own posts" ON posts;
DROP POLICY IF EXISTS "Authenticated users can create posts" ON posts;
DROP POLICY IF EXISTS "Everyone can view posts" ON posts;
DROP POLICY IF EXISTS "Allow all authenticated users" ON posts;
DROP POLICY IF EXISTS "Allow public to read posts" ON posts;
DROP POLICY IF EXISTS "Users can create posts" ON posts;
DROP POLICY IF EXISTS "Posts are publicly viewable" ON posts;
DROP POLICY IF EXISTS "Users can modify their posts" ON posts;
DROP POLICY IF EXISTS "Users can delete their posts" ON posts;

DROP POLICY IF EXISTS "Users can insert likes" ON likes;
DROP POLICY IF EXISTS "Likes are viewable by everyone" ON likes;
DROP POLICY IF EXISTS "Users can delete their own likes" ON likes;
DROP POLICY IF EXISTS "Users can create likes" ON likes;
DROP POLICY IF EXISTS "Likes are viewable" ON likes;
DROP POLICY IF EXISTS "Users can delete their likes" ON likes;

DROP POLICY IF EXISTS "Users can insert comments" ON comments;
DROP POLICY IF EXISTS "Comments are viewable by everyone" ON comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON comments;
DROP POLICY IF EXISTS "Users can create comments" ON comments;
DROP POLICY IF EXISTS "Comments are publicly viewable" ON comments;
DROP POLICY IF EXISTS "Users can modify their comments" ON comments;
DROP POLICY IF EXISTS "Users can delete their comments" ON comments;

DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Allow all for profiles" ON profiles;
DROP POLICY IF EXISTS "Users can manage their own profile" ON profiles;

-- Completely disable RLS on all tables first
ALTER TABLE posts DISABLE ROW LEVEL SECURITY;
ALTER TABLE likes DISABLE ROW LEVEL SECURITY;  
ALTER TABLE comments DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Ensure all users have profile records (critical!)
INSERT INTO profiles (id, username, avatar_url, updated_at)
SELECT 
    au.id,
    COALESCE(au.raw_user_meta_data->>'username', split_part(au.email, '@', 1), 'user') as username,
    null as avatar_url,
    now() as updated_at
FROM auth.users au
WHERE au.id NOT IN (SELECT p.id FROM profiles p WHERE p.id IS NOT NULL)
ON CONFLICT (id) DO NOTHING;

-- Create helper function for ownership checks
CREATE OR REPLACE FUNCTION public.user_is_owner(record_user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN (SELECT auth.uid()) = record_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Profiles Table Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to see their own and other profiles
CREATE POLICY "profiles_select_policy" ON profiles 
FOR SELECT TO authenticated 
USING (true);

-- Users can insert/update only their own profile
CREATE POLICY "profiles_insert_policy" ON profiles
FOR INSERT TO authenticated
WITH CHECK (user_is_owner(id));

CREATE POLICY "profiles_update_policy" ON profiles
FOR UPDATE TO authenticated
USING (user_is_owner(id))
WITH CHECK (user_is_owner(id));

-- Posts Table Policies
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to create posts
CREATE POLICY "posts_insert_policy" ON posts 
FOR INSERT TO authenticated 
WITH CHECK (user_is_owner(user_id));

-- Allow viewing all posts
CREATE POLICY "posts_select_policy" ON posts 
FOR SELECT TO authenticated, anon 
USING (true);

-- Users can update/delete only their own posts
CREATE POLICY "posts_update_policy" ON posts 
FOR UPDATE TO authenticated 
USING (user_is_owner(user_id))
WITH CHECK (user_is_owner(user_id));

CREATE POLICY "posts_delete_policy" ON posts 
FOR DELETE TO authenticated 
USING (user_is_owner(user_id));

-- Comments Table Policies
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to create comments
CREATE POLICY "comments_insert_policy" ON comments 
FOR INSERT TO authenticated 
WITH CHECK (user_is_owner(user_id));

-- Allow viewing all comments
CREATE POLICY "comments_select_policy" ON comments 
FOR SELECT TO authenticated, anon 
USING (true);

-- Users can update/delete only their own comments
CREATE POLICY "comments_update_policy" ON comments 
FOR UPDATE TO authenticated 
USING (user_is_owner(user_id))
WITH CHECK (user_is_owner(user_id));

CREATE POLICY "comments_delete_policy" ON comments 
FOR DELETE TO authenticated 
USING (user_is_owner(user_id));

-- Likes Table Policies
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to create likes
CREATE POLICY "likes_insert_policy" ON likes 
FOR INSERT TO authenticated 
WITH CHECK (user_is_owner(user_id));

-- Allow viewing all likes
CREATE POLICY "likes_select_policy" ON likes 
FOR SELECT TO authenticated, anon 
USING (true);

-- Users can delete their own likes
CREATE POLICY "likes_delete_policy" ON likes 
FOR DELETE TO authenticated 
USING (user_is_owner(user_id));

-- Verification query to check if policies are working
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('posts', 'profiles', 'likes', 'comments')
ORDER BY tablename, policyname;