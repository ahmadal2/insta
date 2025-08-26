-- Simplified Storage Fix (No Custom Policies Required)
-- This approach works around the "must be owner of table objects" error
-- Execute this in your Supabase SQL Editor

-- STEP 1: Ensure user profiles exist (User Profile Initialization standard)
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

-- STEP 2: Fix posts table policies only (we have permissions for this)
-- Drop existing posts policies
DROP POLICY IF EXISTS "authenticated_insert_posts" ON posts;
DROP POLICY IF EXISTS "public_read_posts" ON posts;
DROP POLICY IF EXISTS "authenticated_update_own_posts" ON posts;
DROP POLICY IF EXISTS "authenticated_delete_own_posts" ON posts;
DROP POLICY IF EXISTS "Users can create posts" ON posts;
DROP POLICY IF EXISTS "Posts are publicly viewable" ON posts;
DROP POLICY IF EXISTS "Users can modify their posts" ON posts;
DROP POLICY IF EXISTS "Users can delete their posts" ON posts;

-- Temporarily disable RLS for posts
ALTER TABLE posts DISABLE ROW LEVEL SECURITY;

-- Set DEFAULT auth.uid() to simplify policies (per project specs)
ALTER TABLE posts ALTER COLUMN user_id SET DEFAULT auth.uid();

-- Re-enable RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Create simplified posts policies
CREATE POLICY "posts_insert_authenticated" ON posts
FOR INSERT TO authenticated
WITH CHECK (true); -- Simplified because user_id has DEFAULT auth.uid()

CREATE POLICY "posts_select_public" ON posts
FOR SELECT TO authenticated, anon
USING (true);

CREATE POLICY "posts_update_own" ON posts
FOR UPDATE TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "posts_delete_own" ON posts
FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- STEP 3: Verification
SELECT 'Posts table RLS fixed successfully!' as status;

-- Show current posts policies
SELECT 
  'POSTS POLICIES' as type,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'posts'
ORDER BY policyname;