-- FIX POSTS TABLE SCHEMA MISMATCH
-- The error shows posts table has 'content' column but app expects 'caption'
-- Following Supabase posts table schema requirement memory

-- =====================================================
-- 1️⃣ CHECK CURRENT POSTS TABLE STRUCTURE
-- =====================================================
SELECT 'CURRENT POSTS TABLE STRUCTURE' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'posts' AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- 2️⃣ FIX SCHEMA MISMATCH
-- =====================================================
-- Option A: Rename 'content' column to 'caption' (if content column exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'posts' 
        AND column_name = 'content' 
        AND table_schema = 'public'
    ) THEN
        -- Rename content to caption to match application
        ALTER TABLE posts RENAME COLUMN content TO caption;
        RAISE NOTICE '✅ Renamed content column to caption';
    ELSE
        RAISE NOTICE 'ℹ️ Content column does not exist';
    END IF;
END $$;

-- Option B: Add caption column if it doesn't exist after rename
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'posts' 
        AND column_name = 'caption' 
        AND table_schema = 'public'
    ) THEN
        -- Add caption column as nullable (Instagram posts can have no caption)
        ALTER TABLE posts ADD COLUMN caption text;
        RAISE NOTICE '✅ Added caption column';
    ELSE
        RAISE NOTICE 'ℹ️ Caption column already exists';
    END IF;
END $$;

-- Make caption column nullable (Instagram posts don't require captions)
ALTER TABLE posts ALTER COLUMN caption DROP NOT NULL;

-- =====================================================
-- 3️⃣ ENSURE PROPER DEFAULTS FOR RLS
-- =====================================================
-- Set DEFAULT auth.uid() for user_id (following RLS best practices)
ALTER TABLE posts ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE posts ALTER COLUMN id SET DEFAULT uuid_generate_v4();
ALTER TABLE posts ALTER COLUMN created_at SET DEFAULT now();

-- =====================================================
-- 4️⃣ VERIFY FIXED SCHEMA
-- =====================================================
SELECT 'FIXED POSTS TABLE STRUCTURE' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'caption' AND is_nullable = 'YES' THEN '✅ CAPTION COLUMN NULLABLE'
        WHEN column_name = 'user_id' AND column_default LIKE '%auth.uid()%' THEN '✅ DEFAULT auth.uid() SET'
        WHEN column_name = 'image_url' THEN '✅ IMAGE_URL COLUMN EXISTS'
        ELSE '✅ COLUMN OK'
    END as status
FROM information_schema.columns
WHERE table_name = 'posts' AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- 5️⃣ SUCCESS MESSAGE
-- =====================================================
SELECT 
    '🎉 SCHEMA FIX COMPLETE!' as status,
    'Posts table now has caption column instead of content - matching your Instagram app' as message;