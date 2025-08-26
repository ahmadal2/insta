# Supabase Storage Configuration Guide

## Problem
You're getting `ERROR: 42501: must be owner of table objects` because:
- The `storage.objects` table is owned by the Supabase system
- Your database user doesn't have ownership privileges to modify RLS policies
- Only table owners or superusers can create/drop RLS policies

## Solution: Configure Storage via Dashboard

Since you can't modify `storage.objects` policies directly, use the Supabase Dashboard instead:

### Step 1: Navigate to Storage
1. Go to your Supabase Dashboard
2. Click **Storage** in the left sidebar

### Step 2: Check/Create Images Bucket
1. Look for a bucket named **"images"**
2. If it doesn't exist:
   - Click **"New bucket"**
   - Name: `images`
   - Check **"Public bucket"** ✅
   - Click **"Create bucket"**

### Step 3: Make Bucket Public (CRITICAL)
If the "images" bucket already exists but isn't public:
1. Click on the **"images"** bucket
2. Click **"Settings"** (gear icon)
3. Toggle **"Public bucket"** to **ON** ✅
4. Click **"Save"**

### Step 4: Verify Configuration
After making the bucket public, you should see:
- ✅ **Public bucket** toggle is ON
- The bucket URL should be accessible without authentication

### Step 5: Test Upload
1. Go back to your Instagram app
2. Try uploading a photo
3. The "Storage permission denied" error should now be resolved

## Why This Works
- **Public buckets** don't require RLS policies for basic read/write operations
- Your app can upload to public buckets with just authentication
- This bypasses the need to modify `storage.objects` policies

## Alternative: Database-Only Approach
If you prefer not to make the bucket public, you need:
1. **Superuser access** to your database, OR
2. **Table ownership** of `storage.objects`, OR  
3. Ask your **Supabase admin** to run the storage RLS script

## Files to Run
1. **First**: Run `storage_rls_workaround.sql` to fix database policies
2. **Then**: Follow this guide to configure storage bucket
3. **Finally**: Test your upload functionality

## Verification Commands
```sql
-- Check if bucket is public
SELECT id, name, public 
FROM storage.buckets 
WHERE id = 'images';

-- Should return: public = true
```

## Next Steps
After completing these steps:
1. ✅ Database RLS policies will be fixed
2. ✅ Storage bucket will be configured correctly  
3. ✅ Upload functionality should work
4. ✅ No more "Storage permission denied" errors