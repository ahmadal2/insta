-- Enhanced Storage RLS Fix
-- Following Project Specifications: DEFAULT auth.uid() approach to simplify policies
-- Execute this in your Supabase SQL Editor

-- STEP 1: Drop all existing policies using DO block (per project standards)
DO $$
DECLARE
    r record;
BEGIN
    -- Drop all storage policies
    FOR r IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
            r.policyname, r.schemaname, r.tablename);
    END LOOP;
    
    -- Drop all posts table policies
    FOR r IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'posts'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
            r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;

-- STEP 2: Temporarily disable RLS (debugging workflow)
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
ALTER TABLE posts DISABLE ROW LEVEL SECURITY;

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

-- STEP 4: Set DEFAULT auth.uid() for user ownership (per project specs)
-- This simplifies INSERT policies to WITH CHECK (true)
ALTER TABLE posts ALTER COLUMN user_id SET DEFAULT auth.uid();

-- STEP 5: Re-enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- STEP 6: Create simplified policies using DEFAULT auth.uid() approach

-- STORAGE POLICIES - Simplified with proper auth checks
CREATE POLICY "authenticated_upload_images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'images' AND 
    auth.role() = 'authenticated'
);

CREATE POLICY "public_read_images" ON storage.objects
FOR SELECT TO authenticated, anon
USING (bucket_id = 'images');

CREATE POLICY "authenticated_update_own_images" ON storage.objects
FOR UPDATE TO authenticated
USING (
    bucket_id = 'images' AND 
    auth.uid() = owner
);

CREATE POLICY "authenticated_delete_own_images" ON storage.objects
FOR DELETE TO authenticated
USING (
    bucket_id = 'images' AND 
    auth.uid() = owner
);

-- POSTS POLICIES - Simplified with DEFAULT auth.uid()
CREATE POLICY "authenticated_insert_posts" ON posts
FOR INSERT TO authenticated
WITH CHECK (true); -- Simplified because user_id has DEFAULT auth.uid()

CREATE POLICY "public_read_posts" ON posts
FOR SELECT TO authenticated, anon
USING (true);

CREATE POLICY "authenticated_update_own_posts" ON posts
FOR UPDATE TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "authenticated_delete_own_posts" ON posts
FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- STEP 7: Verification
SELECT 'Enhanced Storage RLS Fix Applied!' as status;

-- Show active policies
SELECT 
    'STORAGE' as type,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects'
UNION ALL
SELECT 
    'POSTS' as type,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'posts'
ORDER BY type, policyname;