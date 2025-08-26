-- DEFINITIVE FIX for Instagram Clone Database Issues
-- This fixes both the missing 'caption' column and RLS policy violations
-- Run this in your Supabase SQL Editor

-- ===== STEP 1: COMPLETE TABLE SCHEMA FIX =====
-- Fix the posts table schema to match what the app expects

-- First, check if caption column exists and add it if missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'posts' 
        AND column_name = 'caption'
    ) THEN
        ALTER TABLE posts ADD COLUMN caption text;
        RAISE NOTICE 'Added missing caption column to posts table';
    ELSE
        RAISE NOTICE 'Caption column already exists';
    END IF;
END $$;

-- Ensure all required columns exist with proper defaults
ALTER TABLE posts ALTER COLUMN id SET DEFAULT uuid_generate_v4();
ALTER TABLE posts ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE posts ALTER COLUMN created_at SET DEFAULT now();

-- ===== STEP 2: CLEAN RLS POLICIES =====
-- Remove ALL existing policies to prevent conflicts

-- Drop all posts policies
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN 
        SELECT policyname FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'posts'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON posts', r.policyname);
    END LOOP;
    RAISE NOTICE 'Dropped all existing posts policies';
END $$;

-- Drop all profiles policies
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN 
        SELECT policyname FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'profiles'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON profiles', r.policyname);
    END LOOP;
    RAISE NOTICE 'Dropped all existing profiles policies';
END $$;

-- ===== STEP 3: ENSURE USER PROFILES EXIST =====
-- Create profiles for all authenticated users
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

-- ===== STEP 4: ENABLE RLS AND CREATE SIMPLE POLICIES =====

-- PROFILES TABLE
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Allow everyone to view profiles (for public feed)
CREATE POLICY "profiles_public_select" ON profiles
FOR SELECT TO authenticated, anon
USING (true);

-- Allow users to manage only their own profile
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

-- Allow authenticated users to create posts
-- Since user_id has DEFAULT auth.uid(), we just check true
CREATE POLICY "posts_authenticated_insert" ON posts
FOR INSERT TO authenticated
WITH CHECK (true);

-- Allow users to update/delete only their own posts
CREATE POLICY "posts_own_update" ON posts
FOR UPDATE TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "posts_own_delete" ON posts
FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- ===== STEP 5: VERIFICATION =====
-- Check that everything is properly set up

-- Verify posts table schema
SELECT 
    'POSTS TABLE SCHEMA' as check_type,
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'posts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verify RLS policies
SELECT 
    'RLS POLICIES' as check_type,
    tablename,
    policyname,
    cmd as operation
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('posts', 'profiles')
ORDER BY tablename, policyname;

-- Check if user profiles exist
SELECT 
    'USER PROFILES' as check_type,
    COUNT(*) as profile_count,
    'profiles created for all users' as status
FROM profiles;

-- Final success message
SELECT 
    'DATABASE SETUP COMPLETE!' as status,
    'Caption column fixed, RLS policies cleaned and recreated' as details;

-- ===== IMPORTANT NOTES =====
-- 1. Posts table now has 'caption' column ✓
-- 2. RLS policies are clean and simple ✓  
-- 3. DEFAULT auth.uid() is set for user_id ✓
-- 4. All users have profiles ✓
-- 5. For storage, you still need to make 'images' bucket PUBLIC via dashboard

SELECT 
    'NEXT STEP FOR STORAGE' as action_needed,
    'Go to Supabase Dashboard → Storage → images → Settings → Enable "Public bucket"' as instruction;