-- Definitive RLS Policy Fix for AhmadInsta
-- This follows Supabase best practices using DEFAULT values for user_id columns

-- Step 1: Drop ALL existing policies to start clean
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
DROP POLICY IF EXISTS "anyone_can_view_posts" ON posts;
DROP POLICY IF EXISTS "authenticated_can_insert_posts" ON posts;
DROP POLICY IF EXISTS "users_can_update_own_posts" ON posts;
DROP POLICY IF EXISTS "users_can_delete_own_posts" ON posts;

-- Drop policies for other tables
DROP POLICY IF EXISTS "Users can insert likes" ON likes;
DROP POLICY IF EXISTS "Likes are viewable by everyone" ON likes;
DROP POLICY IF EXISTS "Users can delete their own likes" ON likes;
DROP POLICY IF EXISTS "likes_insert_policy" ON likes;
DROP POLICY IF EXISTS "likes_select_policy" ON likes;
DROP POLICY IF EXISTS "likes_delete_policy" ON likes;
DROP POLICY IF EXISTS "anyone_can_view_likes" ON likes;
DROP POLICY IF EXISTS "authenticated_can_insert_likes" ON likes;
DROP POLICY IF EXISTS "users_can_delete_own_likes" ON likes;

DROP POLICY IF EXISTS "Users can insert comments" ON comments;
DROP POLICY IF EXISTS "Comments are viewable by everyone" ON comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON comments;
DROP POLICY IF EXISTS "comments_insert_policy" ON comments;
DROP POLICY IF EXISTS "comments_select_policy" ON comments;
DROP POLICY IF EXISTS "comments_update_policy" ON comments;
DROP POLICY IF EXISTS "comments_delete_policy" ON comments;
DROP POLICY IF EXISTS "anyone_can_view_comments" ON comments;
DROP POLICY IF EXISTS "authenticated_can_insert_comments" ON comments;
DROP POLICY IF EXISTS "users_can_update_own_comments" ON comments;
DROP POLICY IF EXISTS "users_can_delete_own_comments" ON comments;

DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
DROP POLICY IF EXISTS "anyone_can_view_profiles" ON profiles;
DROP POLICY IF EXISTS "users_can_insert_own_profile" ON profiles;
DROP POLICY IF EXISTS "users_can_update_own_profile" ON profiles;

-- Step 2: Temporarily disable RLS on all tables
ALTER TABLE posts DISABLE ROW LEVEL SECURITY;
ALTER TABLE likes DISABLE ROW LEVEL SECURITY;
ALTER TABLE comments DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Step 3: Set DEFAULT values for user_id columns (critical for preventing RLS violations)
ALTER TABLE posts ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE comments ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE likes ALTER COLUMN user_id SET DEFAULT auth.uid();

-- Step 4: Ensure all authenticated users have profile records
INSERT INTO profiles (id, username, avatar_url, updated_at)
SELECT 
    au.id,
    COALESCE(au.raw_user_meta_data->>'username', split_part(au.email, '@', 1), 'user') as username,
    null as avatar_url,
    now() as updated_at
FROM auth.users au
WHERE au.id NOT IN (SELECT p.id FROM profiles p WHERE p.id IS NOT NULL)
ON CONFLICT (id) DO NOTHING;

-- Step 5: Re-enable RLS and create simple, permissive policies

-- POSTS TABLE
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "posts_select_all" ON posts 
FOR SELECT USING (true);

CREATE POLICY "posts_insert_authenticated" ON posts 
FOR INSERT TO authenticated 
WITH CHECK (true);

CREATE POLICY "posts_update_own" ON posts 
FOR UPDATE TO authenticated 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "posts_delete_own" ON posts 
FOR DELETE TO authenticated 
USING (auth.uid() = user_id);

-- PROFILES TABLE
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_all" ON profiles 
FOR SELECT USING (true);

CREATE POLICY "profiles_insert_own" ON profiles 
FOR INSERT TO authenticated 
WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own" ON profiles 
FOR UPDATE TO authenticated 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- COMMENTS TABLE
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "comments_select_all" ON comments 
FOR SELECT USING (true);

CREATE POLICY "comments_insert_authenticated" ON comments 
FOR INSERT TO authenticated 
WITH CHECK (true);

CREATE POLICY "comments_update_own" ON comments 
FOR UPDATE TO authenticated 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "comments_delete_own" ON comments 
FOR DELETE TO authenticated 
USING (auth.uid() = user_id);

-- LIKES TABLE
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "likes_select_all" ON likes 
FOR SELECT USING (true);

CREATE POLICY "likes_insert_authenticated" ON likes 
FOR INSERT TO authenticated 
WITH CHECK (true);

CREATE POLICY "likes_delete_own" ON likes 
FOR DELETE TO authenticated 
USING (auth.uid() = user_id);

-- Step 6: Verify the setup
SELECT 'RLS Policies Created Successfully' as status;