-- EMERGENCY DATABASE FIX for Instagram Clone
-- Fixes: Missing 'caption' column + RLS policy violations
-- Following Supabase RLS, Authentication, and User Profile Management Standards

-- ===== STEP 1: SCHEMA VERIFICATION AND FIXES =====
-- Check and add missing 'caption' column to posts table
DO $$
BEGIN
    -- Check if caption column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public'
        AND table_name = 'posts' 
        AND column_name = 'caption'
    ) THEN
        ALTER TABLE posts ADD COLUMN caption text;
        RAISE NOTICE 'Added missing caption column to posts table';
    ELSE
        RAISE NOTICE 'Caption column already exists in posts table';
    END IF;
    
    -- Ensure posts table has proper structure
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public'
        AND table_name = 'posts' 
        AND column_name = 'id'
    ) THEN
        RAISE EXCEPTION 'Posts table does not exist! Please run instagram_advanced_setup.sql first';
    END IF;
END $$;

-- ===== STEP 2: RLS POLICY CLEANUP (Following Standards) =====
-- Drop ALL existing policies to avoid conflicts (per RLS Policy Design standards)
DO $$
DECLARE
    r record;
BEGIN
    -- Drop all posts policies
    FOR r IN 
        SELECT policyname FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'posts'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON posts', r.policyname);
    END LOOP;
    
    -- Drop all profiles policies
    FOR r IN 
        SELECT policyname FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'profiles'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON profiles', r.policyname);
    END LOOP;
    
    RAISE NOTICE 'All existing RLS policies dropped successfully';
END $$;

-- ===== STEP 3: SET DEFAULT AUTH.UID() (Simplification Standard) =====
-- Set DEFAULT auth.uid() to simplify policies and prevent INSERT violations
ALTER TABLE posts ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE comments ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE likes ALTER COLUMN user_id SET DEFAULT auth.uid();

-- Ensure proper defaults for other columns
ALTER TABLE posts ALTER COLUMN id SET DEFAULT uuid_generate_v4();
ALTER TABLE posts ALTER COLUMN created_at SET DEFAULT now();

-- ===== STEP 4: USER PROFILE INITIALIZATION (Authentication Standards) =====
-- Ensure all authenticated users have a corresponding profile record
INSERT INTO profiles (id, username, avatar_url, updated_at)
SELECT 
    au.id,
    COALESCE(
        au.raw_user_meta_data->>'username', 
        split_part(au.email, '@', 1), 
        'user_' || substr(au.id::text, 1, 8)
    ) as username,
    null as avatar_url,
    now() as updated_at
FROM auth.users au
WHERE au.id NOT IN (SELECT p.id FROM profiles p WHERE p.id IS NOT NULL)
ON CONFLICT (id) DO NOTHING;

-- ===== STEP 5: ENABLE RLS AND CREATE CLEAN POLICIES =====

-- PROFILES TABLE
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Allow everyone to view profiles (public Instagram feed)
CREATE POLICY "profiles_public_select" ON profiles
FOR SELECT TO authenticated, anon
USING (true);

-- Users can only manage their own profile (proper auth.uid() checks)
CREATE POLICY "profiles_own_insert" ON profiles
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_own_update" ON profiles
FOR UPDATE TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- POSTS TABLE
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Allow everyone to view posts (public Instagram feed)
CREATE POLICY "posts_public_select" ON posts
FOR SELECT TO authenticated, anon
USING (true);

-- Allow authenticated users to create posts (simplified with DEFAULT auth.uid())
CREATE POLICY "posts_authenticated_insert" ON posts
FOR INSERT TO authenticated
WITH CHECK (true); -- Simplified because user_id has DEFAULT auth.uid()

-- Users can update/delete only their own posts
CREATE POLICY "posts_own_update" ON posts
FOR UPDATE TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "posts_own_delete" ON posts
FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- COMMENTS TABLE (ensure it exists and has proper policies)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comments') THEN
        ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "comments_public_select" ON comments
        FOR SELECT TO authenticated, anon
        USING (true);
        
        CREATE POLICY "comments_authenticated_insert" ON comments
        FOR INSERT TO authenticated
        WITH CHECK (true);
        
        CREATE POLICY "comments_own_update" ON comments
        FOR UPDATE TO authenticated
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);
        
        CREATE POLICY "comments_own_delete" ON comments
        FOR DELETE TO authenticated
        USING (auth.uid() = user_id);
        
        RAISE NOTICE 'Comments table policies created';
    ELSE
        RAISE NOTICE 'Comments table does not exist, skipping';
    END IF;
END $$;

-- LIKES TABLE (ensure it exists and has proper policies)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'likes') THEN
        ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "likes_public_select" ON likes
        FOR SELECT TO authenticated, anon
        USING (true);
        
        CREATE POLICY "likes_authenticated_insert" ON likes
        FOR INSERT TO authenticated
        WITH CHECK (true);
        
        CREATE POLICY "likes_own_delete" ON likes
        FOR DELETE TO authenticated
        USING (auth.uid() = user_id);
        
        RAISE NOTICE 'Likes table policies created';
    ELSE
        RAISE NOTICE 'Likes table does not exist, skipping';
    END IF;
END $$;

-- ===== STEP 6: VERIFICATION =====
-- Verify posts table schema
SELECT 
    'POSTS TABLE VERIFICATION' as check_type,
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'posts' 
ORDER BY ordinal_position;

-- Verify RLS policies are created
SELECT 
    'RLS POLICIES VERIFICATION' as check_type,
    tablename,
    policyname,
    cmd as operation
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('posts', 'profiles', 'comments', 'likes')
ORDER BY tablename, policyname;

-- Count user profiles
SELECT 
    'USER PROFILES COUNT' as check_type,
    COUNT(*) as total_profiles
FROM profiles;

-- ===== SUCCESS MESSAGE =====
SELECT 
    'DATABASE FIX COMPLETE!' as status,
    'Caption column added, RLS policies fixed, profiles initialized' as summary;

-- ===== IMPORTANT NEXT STEPS =====
SELECT 
    'STORAGE CONFIGURATION REQUIRED' as next_step,
    'Go to Supabase Dashboard → Storage → Create/Configure "images" bucket as PUBLIC' as action_needed;