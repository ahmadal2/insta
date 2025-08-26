-- FINAL POSTS TABLE FIX - Based on German Solution
-- Fixes missing 'caption' column + RLS policies for Instagram Clone
-- Following Supabase posts table schema requirement and project specifications

-- =====================================================
-- 1️⃣ Schema von posts prüfen und caption hinzufügen
-- =====================================================
SELECT 'CHECKING POSTS TABLE SCHEMA...' as status;

-- Check current posts table structure
SELECT 
    'CURRENT POSTS COLUMNS' as info,
    column_name, 
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'posts' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Sicherstellen, dass Spalte 'caption' existiert
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name='posts' AND column_name='caption' AND table_schema='public'
    ) THEN
        ALTER TABLE posts ADD COLUMN caption text;
        RAISE NOTICE '✅ Caption column added to posts table';
    ELSE
        RAISE NOTICE 'ℹ️ Caption column already exists';
    END IF;
END $$;

-- Set DEFAULT auth.uid() for user_id (following RLS best practices)
ALTER TABLE posts ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE posts ALTER COLUMN id SET DEFAULT uuid_generate_v4();
ALTER TABLE posts ALTER COLUMN created_at SET DEFAULT now();

-- =====================================================
-- 2️⃣ RLS für Posts aktivieren
-- =====================================================
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 3️⃣ Alte Policies löschen (alle möglichen Varianten)
-- =====================================================
DROP POLICY IF EXISTS "authenticated_insert_posts" ON posts;
DROP POLICY IF EXISTS "public_read_posts" ON posts;
DROP POLICY IF EXISTS "authenticated_update_own_posts" ON posts;
DROP POLICY IF EXISTS "authenticated_delete_own_posts" ON posts;

-- Additional policy names that might exist
DROP POLICY IF EXISTS "Users can create posts" ON posts;
DROP POLICY IF EXISTS "Posts are publicly viewable" ON posts;
DROP POLICY IF EXISTS "Users can modify their posts" ON posts;
DROP POLICY IF EXISTS "Users can delete their posts" ON posts;
DROP POLICY IF EXISTS "posts_authenticated_insert" ON posts;
DROP POLICY IF EXISTS "posts_public_select" ON posts;
DROP POLICY IF EXISTS "posts_own_update" ON posts;
DROP POLICY IF EXISTS "posts_own_delete" ON posts;

-- =====================================================
-- 4️⃣ Neue, saubere Policies erstellen
-- =====================================================
CREATE POLICY "authenticated_insert_posts" ON posts
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "public_read_posts" ON posts
FOR SELECT TO authenticated, anon
USING (true);

CREATE POLICY "authenticated_update_own_posts" ON posts
FOR UPDATE TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "authenticated_delete_own_posts" ON posts
FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- =====================================================
-- 5️⃣ Profile-Tabelle sicherstellen
-- =====================================================
-- Ensure all authenticated users have profiles
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

-- =====================================================
-- 6️⃣ Überprüfung der Posts-Tabelle
-- =====================================================
SELECT 
    '✅ POSTS TABLE VERIFICATION' as check_type,
    column_name,
    data_type,
    CASE 
        WHEN column_name = 'caption' THEN '✅ CAPTION COLUMN EXISTS'
        WHEN column_name = 'user_id' AND column_default LIKE '%auth.uid()%' THEN '✅ DEFAULT auth.uid() SET'
        ELSE '✅ COLUMN OK'
    END as status
FROM information_schema.columns
WHERE table_name = 'posts' AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- 7️⃣ Überprüfung der RLS Policies
-- =====================================================
SELECT 
    '✅ ACTIVE POLICIES' as info,
    policyname,
    cmd as operation
FROM pg_policies
WHERE tablename = 'posts' AND schemaname = 'public'
ORDER BY policyname;

-- =====================================================
-- 8️⃣ Test der Caption-Spalte
-- =====================================================
SELECT 
    '✅ CAPTION COLUMN TEST' as test_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'posts' AND column_name = 'caption' AND table_schema = 'public'
        )
        THEN '✅ Caption column is accessible for INSERT operations'
        ELSE '❌ Caption column still missing'
    END as result;

-- =====================================================
-- 9️⃣ Erfolgs-Nachricht
-- =====================================================
SELECT 
    '🎉 POSTS TABLE FIX COMPLETE!' as status,
    'Caption column added, RLS policies fixed, ready for Instagram uploads!' as message;

-- =====================================================
-- 🔟 Nächste Schritte
-- =====================================================
SELECT 
    '📋 NEXT STEPS' as action,
    'Database schema is now fixed. Test your upload functionality - the caption column error should be resolved.' as instructions;

-- Show final table structure
SELECT 
    '📊 FINAL POSTS TABLE STRUCTURE' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'posts' AND table_schema = 'public'
ORDER BY ordinal_position;