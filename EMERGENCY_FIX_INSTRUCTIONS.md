# 🚨 EMERGENCY FIX GUIDE - Instagram Clone Upload Issues

## Issues Identified:
1. **Database Error**: "Could not find the 'caption' column of 'posts' in the schema cache"
2. **Storage Error**: "new row violates row-level security policy"

## 🔧 IMMEDIATE SOLUTION:

### Step 1: Fix Database Schema and RLS Policies
1. **Go to your Supabase Dashboard**
2. **Click on "SQL Editor"**
3. **Run the emergency fix script**:
   ```
   EMERGENCY_DATABASE_FIX.sql
   ```

This script will:
- ✅ Add the missing `caption` column to posts table
- ✅ Clean all conflicting RLS policies  
- ✅ Set DEFAULT auth.uid() for simplified policies
- ✅ Create clean, working RLS policies
- ✅ Initialize user profiles for all authenticated users

### Step 2: Configure Storage Bucket (CRITICAL)

Since you cannot modify storage.objects policies due to ownership restrictions, configure the bucket as public:

#### Option A: Create New Bucket (if doesn't exist)
1. Go to **Supabase Dashboard** → **Storage**
2. Click **"New bucket"**
3. Name: `images`
4. ✅ Check **"Public bucket"**
5. Click **"Create bucket"**

#### Option B: Make Existing Bucket Public
1. Go to **Supabase Dashboard** → **Storage**
2. Click on **"images"** bucket
3. Click **"Settings"** (gear icon)
4. Toggle **"Public bucket"** to **ON** ✅
5. Click **"Save"**

### Step 3: Verify the Fix
After completing both steps:
1. Go back to your Instagram app
2. Try uploading a photo
3. Both errors should now be resolved:
   - ✅ Database will find the 'caption' column
   - ✅ Storage upload will work with public bucket

## 📋 Why This Works:

| Issue | Root Cause | Solution |
|-------|------------|----------|
| **Missing 'caption' column** | Posts table schema incomplete | Add column to match app expectations |
| **Storage RLS violation** | Complex storage policies + ownership issues | Use public bucket (bypasses RLS entirely) |
| **Database RLS violation** | Conflicting/broken policies | Clean policies + DEFAULT auth.uid() approach |

## 🎯 Following Project Standards:

✅ **RLS Policy Design**: Uses proper auth.uid() checks and DEFAULT values  
✅ **Authentication Standards**: Ensures all users have profiles  
✅ **User Profile Initialization**: Auto-creates profiles for authenticated users  
✅ **Debugging Workflow**: Drop policies → disable RLS → fix → re-enable → test  

## 🚨 If Issues Persist:

1. **Check Supabase Console Logs** for detailed error messages
2. **Verify Authentication** - Make sure you're logged in
3. **Check Environment Variables** - Ensure SUPABASE_URL and SUPABASE_ANON_KEY are correct
4. **Browser Console** - Look for additional error details

## 🔍 Verification Commands:

After running the fix, you can verify in Supabase SQL Editor:

```sql
-- Check if caption column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'posts' AND column_name = 'caption';

-- Check if images bucket is public
SELECT id, name, public 
FROM storage.buckets 
WHERE id = 'images';

-- Check RLS policies
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename IN ('posts', 'profiles');
```

**Expected Results:**
- Caption column should exist in posts table
- Images bucket should show `public = true`
- Clean RLS policies should be listed

Your upload functionality should work perfectly after these fixes! 🚀