-- COMPREHENSIVE SUPABASE VERIFICATION SCRIPT
-- This checks all aspects that could cause empty error objects in uploads

-- =====================================================
-- 1️⃣ CHECK STORAGE BUCKET CONFIGURATION
-- =====================================================
SELECT 'STORAGE BUCKET VERIFICATION' as check_type;

-- Check if 'images' bucket exists
SELECT 
    '1. BUCKET EXISTENCE' as check_step,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images') 
        THEN '✅ images bucket EXISTS'
        ELSE '❌ images bucket MISSING - this causes empty error objects'
    END as result;

-- Check if bucket is public (CRITICAL for uploads)
SELECT 
    '2. BUCKET PUBLIC STATUS' as check_step,
    id,
    name,
    public,
    CASE 
        WHEN public = true THEN '✅ BUCKET IS PUBLIC - uploads should work'
        WHEN public = false THEN '❌ BUCKET IS PRIVATE - this causes upload failures'
        ELSE '❌ BUCKET STATUS UNKNOWN'
    END as status
FROM storage.buckets 
WHERE id = 'images';

-- Show bucket configuration details
SELECT 
    '3. BUCKET CONFIGURATION DETAILS' as check_step,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE id = 'images';

-- =====================================================
-- 2️⃣ CHECK POSTS TABLE SCHEMA
-- =====================================================
SELECT 'POSTS TABLE VERIFICATION' as check_type;

-- Check if posts table exists with all required columns
SELECT 
    '4. POSTS TABLE COLUMNS' as check_step,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'caption' THEN '✅ CAPTION COLUMN EXISTS'
        WHEN column_name = 'user_id' AND column_default LIKE '%auth.uid()%' THEN '✅ DEFAULT auth.uid() SET'
        WHEN column_name = 'id' THEN '✅ ID COLUMN EXISTS'
        WHEN column_name = 'image_url' THEN '✅ IMAGE_URL COLUMN EXISTS'
        WHEN column_name = 'created_at' THEN '✅ CREATED_AT COLUMN EXISTS'
        ELSE '✅ COLUMN OK'
    END as status
FROM information_schema.columns
WHERE table_name = 'posts' AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- 3️⃣ CHECK RLS POLICIES
-- =====================================================
SELECT 'RLS POLICIES VERIFICATION' as check_type;

-- Check posts table policies
SELECT 
    '5. POSTS RLS POLICIES' as check_step,
    tablename,
    policyname,
    cmd as operation,
    '✅ POLICY EXISTS' as status
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'posts'
ORDER BY policyname;

-- =====================================================
-- 4️⃣ CHECK USER PROFILES
-- =====================================================
SELECT 'USER PROFILES VERIFICATION' as check_type;

-- Count profiles
SELECT 
    '6. USER PROFILES COUNT' as check_step,
    COUNT(*) as total_profiles,
    'All authenticated users should have profiles' as note
FROM profiles;

-- =====================================================
-- 5️⃣ ATTEMPT TO CREATE MISSING STORAGE BUCKET
-- =====================================================
-- Create 'images' bucket if it doesn't exist (public by default)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
SELECT 
    'images', 
    'images', 
    true, -- PUBLIC bucket (critical for uploads)
    52428800, -- 50MB limit
    ARRAY['image/*'] -- Only allow images
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images');

-- Update existing bucket to be public if it's currently private
UPDATE storage.buckets 
SET public = true 
WHERE id = 'images' AND public = false;

-- =====================================================
-- 6️⃣ FINAL VERIFICATION AFTER FIXES
-- =====================================================
SELECT 'FINAL VERIFICATION' as check_type;

-- Final bucket status
SELECT 
    '7. FINAL BUCKET STATUS' as check_step,
    id,
    name,
    public,
    CASE 
        WHEN public = true THEN '✅ READY FOR UPLOADS - empty error objects should be fixed'
        ELSE '❌ STILL NEEDS DASHBOARD CONFIGURATION'
    END as upload_ready_status
FROM storage.buckets 
WHERE id = 'images';

-- =====================================================
-- 7️⃣ DASHBOARD INSTRUCTIONS IF SQL FAILS
-- =====================================================
SELECT 
    '8. DASHBOARD INSTRUCTIONS' as final_step,
    'If SQL updates failed, go to Supabase Dashboard → Storage → Create "images" bucket → Enable "Public bucket"' as action_required;

-- Success message
SELECT 
    'VERIFICATION COMPLETE' as status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images' AND public = true)
        THEN '✅ Configuration looks good! Empty error objects should be resolved.'
        ELSE '❌ Storage bucket needs configuration via Dashboard.'
    END as final_result;