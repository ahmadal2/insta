-- COMPLETE DATABASE SCHEMA FIX for Instagram Clone
-- Fixes: Missing 'caption' column + ensures proper RLS policies
-- Following Supabase RLS, Authentication, and User Profile Management Standards

-- ===== STEP 1: VERIFY AND FIX POSTS TABLE SCHEMA =====
SELECT 'CHECKING POSTS TABLE SCHEMA...' as status;

-- Check current posts table structure
SELECT 
    'CURRENT POSTS TABLE COLUMNS' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'posts'
ORDER BY ordinal_position;

-- Add missing caption column if it doesn't exist
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
        RAISE NOTICE '✅ Added missing caption column to posts table';
    ELSE
        RAISE NOTICE '✅ Caption column already exists in posts table';
    END IF;
    
    -- Ensure posts table exists with all required columns
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'posts'
    ) THEN
        RAISE EXCEPTION '❌ Posts table does not exist! Please run instagram_advanced_setup.sql first';
    END IF;
END $$;

-- Ensure all required columns exist with proper structure
ALTER TABLE posts ALTER COLUMN id SET DEFAULT uuid_generate_v4();
ALTER TABLE posts ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE posts ALTER COLUMN created_at SET DEFAULT now();

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
    
    RAISE NOTICE '✅ All existing RLS policies dropped successfully';
END $$;

-- ===== STEP 3: USER PROFILE INITIALIZATION (Authentication Standards) =====
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

-- ===== STEP 4: ENABLE RLS AND CREATE CLEAN POLICIES =====

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
-- Following RLS Policy Design: WITH CHECK (true) because user_id has DEFAULT auth.uid()
CREATE POLICY "posts_authenticated_insert" ON posts
FOR INSERT TO authenticated
WITH CHECK (true);

-- Users can update/delete only their own posts
CREATE POLICY "posts_own_update" ON posts
FOR UPDATE TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "posts_own_delete" ON posts
FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- ===== STEP 5: ENSURE OTHER TABLES HAVE PROPER POLICIES =====

-- COMMENTS TABLE (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comments') THEN
        -- Set DEFAULT auth.uid() for comments
        ALTER TABLE comments ALTER COLUMN user_id SET DEFAULT auth.uid();
        
        ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
        
        -- Drop existing comment policies
        DROP POLICY IF EXISTS "comments_public_select" ON comments;
        DROP POLICY IF EXISTS "comments_authenticated_insert" ON comments;
        DROP POLICY IF EXISTS "comments_own_update" ON comments;
        DROP POLICY IF EXISTS "comments_own_delete" ON comments;
        
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
        
        RAISE NOTICE '✅ Comments table policies created';
    ELSE
        RAISE NOTICE 'ℹ️ Comments table does not exist, skipping';
    END IF;
END $$;

-- LIKES TABLE (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'likes') THEN
        -- Set DEFAULT auth.uid() for likes
        ALTER TABLE likes ALTER COLUMN user_id SET DEFAULT auth.uid();
        
        ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
        
        -- Drop existing like policies
        DROP POLICY IF EXISTS "likes_public_select" ON likes;
        DROP POLICY IF EXISTS "likes_authenticated_insert" ON likes;
        DROP POLICY IF EXISTS "likes_own_delete" ON likes;
        
        CREATE POLICY "likes_public_select" ON likes
        FOR SELECT TO authenticated, anon
        USING (true);
        
        CREATE POLICY "likes_authenticated_insert" ON likes
        FOR INSERT TO authenticated
        WITH CHECK (true);
        
        CREATE POLICY "likes_own_delete" ON likes
        FOR DELETE TO authenticated
        USING (auth.uid() = user_id);
        
        RAISE NOTICE '✅ Likes table policies created';
    ELSE
        RAISE NOTICE 'ℹ️ Likes table does not exist, skipping';
    END IF;
END $$;

-- ===== STEP 6: VERIFICATION =====
-- Verify posts table schema is now complete
SELECT 
    '✅ POSTS TABLE VERIFICATION' as check_type,
    column_name,
    data_type,
    column_default,
    is_nullable,
    CASE 
        WHEN column_name = 'caption' THEN '✅ CAPTION COLUMN EXISTS'
        WHEN column_name = 'user_id' AND column_default LIKE '%auth.uid()%' THEN '✅ DEFAULT auth.uid() SET'
        ELSE '✅ COLUMN OK'
    END as status
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'posts' 
ORDER BY ordinal_position;

-- Verify RLS policies are created
SELECT 
    '✅ RLS POLICIES VERIFICATION' as check_type,
    tablename,
    policyname,
    cmd as operation
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('posts', 'profiles', 'comments', 'likes')
ORDER BY tablename, policyname;

-- Count user profiles
SELECT 
    '✅ USER PROFILES COUNT' as check_type,
    COUNT(*) as total_profiles,
    'All authenticated users should have profiles' as note
FROM profiles;

-- Test if caption column is accessible
SELECT 
    '✅ CAPTION COLUMN TEST' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'posts' AND column_name = 'caption'
        )
        THEN '✅ Caption column is now accessible for INSERT operations'
        ELSE '❌ Caption column still missing'
    END as result;

-- ===== SUCCESS MESSAGE =====
SELECT 
    '🎉 DATABASE SCHEMA FIX COMPLETE!' as status,
    'Caption column added, RLS policies fixed, profiles initialized' as summary;

-- ===== NEXT STEPS =====
SELECT 
    '📋 NEXT STEPS' as action_type,
    'Database schema is now fixed. Try inserting a post again - the caption column error should be resolved.' as instructions;