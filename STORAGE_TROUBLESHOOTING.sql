-- STORAGE TROUBLESHOOTING AND FIX
-- Run this in Supabase SQL Editor to diagnose and fix storage issues

-- ===== STEP 1: DIAGNOSE CURRENT STORAGE SETUP =====
SELECT 'STORAGE BUCKET DIAGNOSIS' as check_type;

-- Check if 'images' bucket exists and its configuration
SELECT 
    'BUCKET STATUS' as type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images') 
        THEN '✅ images bucket EXISTS'
        ELSE '❌ images bucket MISSING - needs to be created'
    END as bucket_existence,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images' AND public = true) 
        THEN '✅ Bucket is PUBLIC (correct for uploads)'
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images' AND public = false)
        THEN '❌ Bucket is PRIVATE (this causes upload errors)'
        ELSE '❌ Bucket does not exist'
    END as public_status;

-- Show current bucket details if it exists
SELECT 
    'CURRENT BUCKET CONFIG' as type,
    id as bucket_id,
    name as bucket_name,
    public as is_public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE id = 'images';

-- ===== STEP 2: CHECK STORAGE POLICIES =====
SELECT 'STORAGE POLICIES CHECK' as check_type;

-- List all storage policies for objects table
SELECT 
    'EXISTING STORAGE POLICIES' as type,
    policyname,
    cmd as operation,
    qual as condition,
    with_check as with_check_condition
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
ORDER BY policyname;

-- ===== STEP 3: ATTEMPT TO CREATE/FIX BUCKET =====
-- Create 'images' bucket if it doesn't exist (public by default)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
SELECT 
    'images', 
    'images', 
    true, -- PUBLIC bucket
    52428800, -- 50MB limit
    ARRAY['image/*'] -- Only allow images
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images');

-- Update existing bucket to be public if it's currently private
UPDATE storage.buckets 
SET 
    public = true,
    allowed_mime_types = ARRAY['image/*'],
    file_size_limit = COALESCE(file_size_limit, 52428800)
WHERE id = 'images' 
AND public = false;

-- ===== STEP 4: VERIFY THE FIX =====
SELECT 'VERIFICATION AFTER FIX' as check_type;

-- Final verification
SELECT 
    'FINAL BUCKET STATUS' as type,
    id,
    name,
    public,
    CASE 
        WHEN public = true THEN '✅ READY FOR UPLOADS'
        ELSE '❌ STILL NEEDS DASHBOARD CONFIGURATION'
    END as upload_ready_status,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'images';

-- ===== STEP 5: GENERATE NEXT STEPS =====
SELECT 
    'NEXT STEPS' as action_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images' AND public = true)
        THEN '✅ SQL fix successful! Try uploading again in your app.'
        ELSE '❌ SQL fix failed. Use Supabase Dashboard: Storage → images → Settings → Enable "Public bucket"'
    END as instructions;

-- Show the exact dashboard path
SELECT 
    'DASHBOARD INSTRUCTIONS' as type,
    'Go to: Supabase Dashboard → Storage → images bucket → Settings (gear icon) → Toggle "Public bucket" ON → Save' as exact_steps;