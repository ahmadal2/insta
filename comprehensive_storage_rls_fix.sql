-- Comprehensive Storage and Database RLS Fix
-- Follows RLS Policy Management Workflow from project specifications
-- Execute this in your Supabase SQL Editor

-- STEP 1: Drop all existing policies using DO block (as per specification)
DO $$
DECLARE
    r record;
BEGIN
    -- Drop all posts table policies
    FOR r IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'posts'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
            r.policyname, r.schemaname, r.tablename);
    END LOOP;
    
    -- Drop all storage policies
    FOR r IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
            r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;

-- STEP 2: Temporarily disable RLS on tables (debugging workflow)
ALTER TABLE posts DISABLE ROW LEVEL SECURITY;
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- STEP 3: Initialize user profiles (User Profile Initialization standard)
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

-- STEP 4: Re-enable RLS on tables
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- STEP 5: Create clean policies with proper USING and WITH CHECK conditions

-- DATABASE POLICIES FOR POSTS TABLE
-- Using proper auth.uid() checks as per RLS Policy Design standards
CREATE POLICY "authenticated_users_insert_posts" ON posts
FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "everyone_view_posts" ON posts
FOR SELECT TO authenticated, anon
USING (true);

CREATE POLICY "users_update_own_posts" ON posts
FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "users_delete_own_posts" ON posts
FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- STORAGE POLICIES FOR IMAGES BUCKET
-- Following Storage Configuration memory requirements

-- Allow authenticated users to upload to images bucket
CREATE POLICY "authenticated_users_upload_images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'images' AND 
    (SELECT auth.uid()) = owner
);

-- Allow everyone to view images (public bucket requirement)
CREATE POLICY "everyone_view_images" ON storage.objects
FOR SELECT TO authenticated, anon
USING (bucket_id = 'images');

-- Allow users to update their own images
CREATE POLICY "users_update_own_images" ON storage.objects
FOR UPDATE TO authenticated
USING (
    bucket_id = 'images' AND 
    (SELECT auth.uid()) = owner
)
WITH CHECK (
    bucket_id = 'images' AND 
    (SELECT auth.uid()) = owner
);

-- Allow users to delete their own images
CREATE POLICY "users_delete_own_images" ON storage.objects
FOR DELETE TO authenticated
USING (
    bucket_id = 'images' AND 
    (SELECT auth.uid()) = owner
);

-- STEP 6: Ensure storage bucket exists and is properly configured
-- Note: This must be done manually in Supabase Dashboard if bucket doesn't exist

-- STEP 7: Verification queries
SELECT 'Comprehensive RLS Fix Applied Successfully!' as status;

-- Show current database policies
SELECT 
    'DATABASE POLICIES' as type,
    schemaname,
    tablename,
    policyname
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'posts'

UNION ALL

-- Show current storage policies  
SELECT 
    'STORAGE POLICIES' as type,
    schemaname,
    tablename,
    policyname
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname LIKE '%images%'

ORDER BY type, policyname;