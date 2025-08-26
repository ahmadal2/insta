-- STORAGE VERIFICATION AND FIX CHECKLIST
-- Following Supabase storage configuration memory requirements
-- Run this in Supabase SQL Editor

-- ===== 1. CHECK IF IMAGES BUCKET EXISTS =====
SELECT 
    '1. BUCKET EXISTENCE CHECK' as step,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images') 
        THEN '✅ images bucket EXISTS'
        ELSE '❌ images bucket MISSING - must be created in dashboard'
    END as result;

-- ===== 2. CHECK IF BUCKET IS PUBLIC =====
SELECT 
    '2. PUBLIC BUCKET CHECK' as step,
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

-- ===== 3. CHECK BUCKET CONFIGURATION =====
SELECT 
    '3. BUCKET CONFIGURATION' as step,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE id = 'images';

-- ===== 4. ATTEMPT TO CREATE PUBLIC BUCKET (if missing) =====
-- This will only work if bucket doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
SELECT 
    'images', 
    'images', 
    true, -- PUBLIC bucket (critical for uploads)
    52428800, -- 50MB limit
    ARRAY['image/*'] -- Only allow images
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images');

-- ===== 5. UPDATE EXISTING BUCKET TO BE PUBLIC =====
-- This attempts to make private bucket public
UPDATE storage.buckets 
SET public = true 
WHERE id = 'images' AND public = false;

-- ===== 6. FINAL VERIFICATION =====
SELECT 
    '6. FINAL STATUS' as step,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images' AND public = true)
        THEN '✅ SUCCESS: images bucket is PUBLIC and ready for uploads!'
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images' AND public = false)
        THEN '❌ BUCKET EXISTS but is PRIVATE - use dashboard to make it public'
        ELSE '❌ BUCKET MISSING - create it in Supabase Dashboard'
    END as final_result;

-- ===== 7. DASHBOARD INSTRUCTIONS =====
SELECT 
    '7. DASHBOARD INSTRUCTIONS' as step,
    'If SQL updates failed, go to Supabase Dashboard → Storage → images → Settings → Enable "Public bucket"' as action_required;