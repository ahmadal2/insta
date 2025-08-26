-- Comprehensive RLS Setup - Solution 1 (Frontend sets user_id explicitly)
-- Step-by-step implementation following best practices

-- Step 1: Delete all existing policies
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename IN ('posts', 'likes', 'comments', 'profiles')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
            r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;

-- Step 2: Temporarily disable RLS on all tables
ALTER TABLE posts DISABLE ROW LEVEL SECURITY;
ALTER TABLE likes DISABLE ROW LEVEL SECURITY;
ALTER TABLE comments DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Step 3: Create profiles for all users
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

-- Step 4: Re-enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- Step 5: Create comprehensive policies

-- PROFILES POLICIES
-- Everyone can view profiles
CREATE POLICY "Profiles are viewable by everyone" ON profiles
FOR SELECT TO authenticated, anon
USING (true);

-- Only user can manage their own profile
CREATE POLICY "Users can manage their own profile" ON profiles
FOR ALL TO authenticated
USING ((SELECT auth.uid()) = id)
WITH CHECK ((SELECT auth.uid()) = id);

-- POSTS POLICIES
-- Authenticated users can create posts (must provide user_id explicitly)
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
-- Authenticated users can create comments (must provide user_id explicitly)
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
-- Authenticated users can create likes (must provide user_id explicitly)
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

-- Step 6: Verification
SELECT 'RLS Policies Setup Complete - Solution 1 (Explicit user_id)' as status;

-- Verify policies are created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('posts', 'profiles', 'likes', 'comments')
ORDER BY tablename, policyname;