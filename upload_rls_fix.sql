-- Quick Fix for Upload RLS Error
-- Execute this in your Supabase SQL Editor

-- Step 1: First ensure all users have profiles
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

-- Step 2: Drop existing problematic policies
DROP POLICY IF EXISTS "Users can create posts" ON posts;
DROP POLICY IF EXISTS "Posts are publicly viewable" ON posts;
DROP POLICY IF EXISTS "Users can modify their posts" ON posts;
DROP POLICY IF EXISTS "Users can delete their posts" ON posts;

-- Step 3: Create simple, working policies for posts
-- Allow authenticated users to insert posts
CREATE POLICY "authenticated_users_can_insert_posts" ON posts
FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

-- Allow everyone to view posts
CREATE POLICY "everyone_can_view_posts" ON posts
FOR SELECT TO authenticated, anon
USING (true);

-- Allow users to update their own posts
CREATE POLICY "users_can_update_own_posts" ON posts
FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

-- Allow users to delete their own posts
CREATE POLICY "users_can_delete_own_posts" ON posts
FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- Step 4: Ensure RLS is enabled
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Step 5: Verify the setup
SELECT 'RLS Fix Applied Successfully!' as status;

-- Show current policies
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'posts'
ORDER BY policyname;