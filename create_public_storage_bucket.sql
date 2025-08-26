-- Create Public Storage Bucket for Images
-- Run this in Supabase SQL Editor if dashboard method doesn't work

-- Check if 'images' bucket exists
SELECT 
    'BUCKET STATUS' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images') 
        THEN 'images bucket EXISTS'
        ELSE 'images bucket MISSING'
    END as status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images' AND public = true) 
        THEN 'Bucket is PUBLIC ✅'
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images' AND public = false)
        THEN 'Bucket is PRIVATE ❌ - needs to be made public'
        ELSE 'Bucket does not exist'
    END as public_status;

-- Create the 'images' bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
SELECT 'images', 'images', true, 52428800, ARRAY['image/*']
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images');

-- Update existing bucket to be public if it exists but is private
UPDATE storage.buckets 
SET public = true 
WHERE id = 'images' AND public = false;

-- Verify the bucket configuration
SELECT 
    'FINAL VERIFICATION' as check_type,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'images';

-- Success message
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images' AND public = true)
        THEN '✅ SUCCESS: images bucket is now PUBLIC and ready for uploads!'
        ELSE '❌ ISSUE: Please use Supabase Dashboard to make bucket public'
    END as final_status;