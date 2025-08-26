-- Storage RLS Workaround für ahmad-insta
-- This script works around the "must be owner of table objects" error
-- by focusing on what we CAN control without table ownership

-- Step 1: Check current storage setup
SELECT 'CHECKING STORAGE SETUP...' as status;

-- Check if 'images' bucket exists
SELECT 
    'BUCKET STATUS' as type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images') 
        THEN 'images bucket EXISTS' 
        ELSE 'images bucket MISSING - CREATE IT FIRST!' 
    END as message;

-- Check existing storage policies (read-only check)
SELECT 
    'EXISTING POLICIES' as type,
    policyname,
    cmd as operation,
    roles,
    qual as condition
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects'
ORDER BY policyname;

-- Step 2: Database-level fixes (we have permissions for these)
SELECT 'FIXING DATABASE TABLES...' as status;

-- Ensure profiles table exists and has proper RLS
CREATE TABLE IF NOT EXISTS profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text,
  avatar_url text,
  bio text,
  updated_at timestamp with time zone default now()
);

-- Enable RLS on profiles (we own this table)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing profile policies safely
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;

-- Create clean profile policies
CREATE POLICY "profiles_select_policy" ON profiles
FOR SELECT TO authenticated, anon
USING (true);

CREATE POLICY "profiles_insert_policy" ON profiles
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_policy" ON profiles
FOR UPDATE TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Step 3: Fix posts table RLS (we have permissions for this)
-- Enable RLS on posts
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Drop existing posts policies safely
DROP POLICY IF EXISTS "posts_select_policy" ON posts;
DROP POLICY IF EXISTS "posts_insert_policy" ON posts;
DROP POLICY IF EXISTS "posts_update_policy" ON posts;
DROP POLICY IF EXISTS "posts_delete_policy" ON posts;

-- Create clean posts policies using DEFAULT auth.uid() approach
CREATE POLICY "posts_select_policy" ON posts
FOR SELECT TO authenticated, anon
USING (true);

CREATE POLICY "posts_insert_policy" ON posts
FOR INSERT TO authenticated
WITH CHECK (true); -- Allow insert since user_id will be set by DEFAULT auth.uid()

CREATE POLICY "posts_update_policy" ON posts
FOR UPDATE TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "posts_delete_policy" ON posts
FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- Step 4: Ensure user profiles exist for all authenticated users
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

-- Step 5: Set DEFAULT auth.uid() on posts.user_id (if not already set)
DO $$
BEGIN
    -- Check if DEFAULT is already set
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'posts' 
        AND column_name = 'user_id' 
        AND column_default LIKE '%auth.uid()%'
    ) THEN
        -- Set DEFAULT auth.uid() for user_id
        ALTER TABLE posts ALTER COLUMN user_id SET DEFAULT auth.uid();
        RAISE NOTICE 'Set DEFAULT auth.uid() on posts.user_id';
    ELSE
        RAISE NOTICE 'DEFAULT auth.uid() already set on posts.user_id';
    END IF;
END $$;

-- Step 6: Verification and next steps
SELECT 'DATABASE RLS SETUP COMPLETE!' as status;

-- Show what we successfully configured
SELECT 
    'DATABASE POLICIES' as type,
    schemaname,
    tablename,
    policyname,
    cmd as operation
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('posts', 'profiles')
ORDER BY tablename, policyname;

-- Final message about storage
SELECT 'IMPORTANT STORAGE CONFIGURATION NEEDED!' as type,
       'Since we cannot modify storage.objects policies due to ownership,' ||
       ' you MUST configure the "images" bucket as PUBLIC in Supabase Dashboard.' ||
       ' Go to Storage → images → Settings → Enable "Public bucket"' as message;

-- Show current user info for debugging
SELECT 
    'CURRENT USER INFO' as type,
    current_user as db_user,
    (SELECT rolsuper FROM pg_authid WHERE rolname = current_user) as is_superuser,
    'If is_superuser = false, you cannot modify storage.objects directly' as note;