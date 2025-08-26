# Upload Error: RLS Policy Violation - Fix Guide

## Problem
Getting "new row violates row-level security policy" when trying to upload posts.

## Root Causes
1. Missing or incorrect RLS policies for the `posts` table
2. User profile not created in `profiles` table
3. Missing Supabase Storage bucket
4. User not properly authenticated

## Step-by-Step Solution

### Step 1: Execute RLS Fix (REQUIRED)
1. Open your Supabase Dashboard: https://supabase.com/dashboard
2. Go to your project
3. Click "SQL Editor" in the left sidebar
4. Click "New Query"
5. Copy and paste the entire content from `upload_rls_fix.sql`
6. Click "Run" to execute

### Step 2: Create Storage Bucket (REQUIRED)
1. In Supabase Dashboard, go to "Storage"
2. Click "Create new bucket"
3. Name it exactly: `images`
4. Make it **Public**
5. Click "Create bucket"

### Step 3: Set Storage Policies
After creating the bucket, set these policies:

```sql
-- Allow authenticated users to upload images
CREATE POLICY "authenticated_users_can_upload" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'images');

-- Allow everyone to view images
CREATE POLICY "everyone_can_view_images" ON storage.objects
FOR SELECT TO authenticated, anon
USING (bucket_id = 'images');

-- Allow users to delete their own images
CREATE POLICY "users_can_delete_own_images" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'images' AND (SELECT auth.uid()) = owner);
```

### Step 4: Test the Fix
1. Log out and log back in to your application
2. Try uploading a post
3. Check browser console for any errors

### Common Issues & Solutions

#### Issue: "Bucket not found"
- **Solution**: Create the "images" bucket in Supabase Storage (Step 2)

#### Issue: Still getting RLS violation
- **Solution**: 
  1. Execute `upload_rls_fix.sql` (Step 1)
  2. Log out and log back in
  3. Try again

#### Issue: "Profile not found"
- **Solution**: The RLS fix script creates profiles automatically

#### Issue: "Not authenticated"
- **Solution**: 
  1. Check if you're logged in
  2. Clear browser cache and cookies
  3. Log in again

### Verification Commands
Run these in Supabase SQL Editor to verify setup:

```sql
-- Check if your user has a profile
SELECT * FROM profiles WHERE id = (SELECT auth.uid());

-- Check RLS policies for posts
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'posts';

-- Check if storage bucket exists
SELECT * FROM storage.buckets WHERE name = 'images';
```

### Alternative: Disable RLS Temporarily (For Testing Only)
If you need to test quickly, you can temporarily disable RLS:

```sql
-- TEMPORARY - FOR TESTING ONLY
ALTER TABLE posts DISABLE ROW LEVEL SECURITY;
```

**⚠️ WARNING**: Never leave RLS disabled in production!

After testing, re-enable it:
```sql
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
```

### Contact Information
If the issue persists after following all steps:
1. Check browser console for detailed error messages
2. Verify all environment variables are correct
3. Ensure you've executed both the RLS fix and created the storage bucket