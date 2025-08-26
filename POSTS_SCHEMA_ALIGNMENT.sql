-- POSTS TABLE SCHEMA ALIGNMENT FIX
-- Error: null value in column "content" violates not-null constraint
-- Solution: Rename 'content' to 'caption' and make it nullable
-- Following Supabase posts table schema requirement memory

-- =====================================================
-- 1️⃣ DIAGNOSE CURRENT SCHEMA ISSUE
-- =====================================================
SELECT 'CURRENT POSTS TABLE DIAGNOSIS' as step;

-- Show current problematic structure
SELECT 
    'CURRENT COLUMNS' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'content' AND is_nullable = 'NO' THEN '❌ CONTENT COLUMN IS NOT NULL (causing error)'
        WHEN column_name = 'caption' THEN '✅ CAPTION COLUMN EXISTS'
        ELSE '📋 OTHER COLUMN'
    END as issue_status
FROM information_schema.columns
WHERE table_name = 'posts' AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- 2️⃣ FIX SCHEMA MISMATCH
-- =====================================================
-- Rename 'content' column to 'caption' (following memory requirement)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'posts' 
        AND column_name = 'content' 
        AND table_schema = 'public'
    ) THEN
        -- Rename content to caption to match Instagram app requirements
        ALTER TABLE posts RENAME COLUMN content TO caption;
        RAISE NOTICE '✅ Renamed content column to caption (following memory requirement)';
    ELSE
        RAISE NOTICE 'ℹ️ Content column does not exist, checking for caption...';
    END IF;
END $$;

-- Ensure caption column exists and is nullable (Instagram posts can have empty captions)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'posts' 
        AND column_name = 'caption' 
        AND table_schema = 'public'
    ) THEN
        -- Add caption column if it doesn't exist
        ALTER TABLE posts ADD COLUMN caption text;
        RAISE NOTICE '✅ Added caption column';
    END IF;
    
    -- Make caption nullable (Instagram posts don't require captions)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'posts' 
        AND column_name = 'caption' 
        AND is_nullable = 'NO'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE posts ALTER COLUMN caption DROP NOT NULL;
        RAISE NOTICE '✅ Made caption column nullable';
    END IF;
END $$;

-- =====================================================
-- 3️⃣ ENSURE PROPER RLS CONFIGURATION
-- =====================================================
-- Set DEFAULT auth.uid() for user_id (simplifies RLS policies)
ALTER TABLE posts ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE posts ALTER COLUMN id SET DEFAULT uuid_generate_v4();
ALTER TABLE posts ALTER COLUMN created_at SET DEFAULT now();

-- =====================================================
-- 4️⃣ VERIFY FIXED SCHEMA
-- =====================================================
SELECT 'FIXED POSTS TABLE VERIFICATION' as step;

SELECT 
    'FIXED STRUCTURE' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'caption' AND is_nullable = 'YES' THEN '✅ CAPTION NULLABLE (Instagram standard)'
        WHEN column_name = 'user_id' AND column_default LIKE '%auth.uid()%' THEN '✅ DEFAULT auth.uid() SET'
        WHEN column_name = 'image_url' THEN '✅ IMAGE_URL COLUMN'
        WHEN column_name = 'id' THEN '✅ ID COLUMN'
        WHEN column_name = 'created_at' THEN '✅ CREATED_AT COLUMN'
        ELSE '✅ COLUMN OK'
    END as status
FROM information_schema.columns
WHERE table_name = 'posts' AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- 5️⃣ TEST SCHEMA COMPATIBILITY
-- =====================================================
-- Verify the fix works by checking constraint violations are resolved
SELECT 
    'SCHEMA COMPATIBILITY TEST' as test_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'posts' 
            AND column_name = 'caption' 
            AND is_nullable = 'YES'
            AND table_schema = 'public'
        )
        THEN '✅ Schema now matches Instagram app - uploads should work!'
        ELSE '❌ Schema still has issues'
    END as result;

-- =====================================================
-- 6️⃣ SUCCESS MESSAGE
-- =====================================================
SELECT 
    '🎉 POSTS SCHEMA ALIGNMENT COMPLETE!' as status,
    'content → caption column renamed, nullable constraint fixed' as details,
    'Instagram upload functionality should now work without NULL constraint errors' as next_steps;