# Storage RLS Error - Complete Fix Guide

## Error: "new row violates row-level security policy" in Storage

This error occurs when Supabase Storage RLS policies are not properly configured. Following the project's RLS debugging workflow:

## 🚨 IMMEDIATE FIXES (Execute in Order)

### Step 1: Execute Comprehensive RLS Fix
1. **Go to Supabase Dashboard** → SQL Editor
2. **Copy and paste** `comprehensive_storage_rls_fix.sql` 
3. **Click "Run"** to execute the complete fix

### Step 2: Create Storage Bucket (If Missing)
1. **Supabase Dashboard** → Storage
2. **Create new bucket** named exactly: `images`
3. **Make it Public** (enable public access)
4. **Save**

### Step 3: Verify Storage Policies
Run this in SQL Editor to check policies:
```sql
-- Check storage policies
SELECT policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects'
AND policyname LIKE '%images%';
```

### Step 4: Test Authentication
1. **Log out** of your application completely
2. **Clear browser cache** and cookies
3. **Log back in**
4. **Try upload again**

## 🔍 Root Cause Analysis

The error occurs because:
1. **Missing storage RLS policies** for the `images` bucket
2. **Incorrect policy configuration** - not allowing authenticated users
3. **Missing bucket** or incorrect bucket name
4. **Authentication state issues** - stale JWT tokens

## 💡 Alternative Solutions

### Solution A: Temporary Disable Storage RLS (Testing Only)
```sql
-- TEMPORARY - FOR TESTING ONLY
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
```
**⚠️ WARNING**: Re-enable after testing:
```sql
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
```

### Solution B: Manual Policy Creation
If the comprehensive fix doesn't work, create policies manually:

```sql
-- Allow authenticated users to upload to images bucket
CREATE POLICY "auth_users_upload_images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'images');

-- Allow everyone to view images
CREATE POLICY "public_view_images" ON storage.objects
FOR SELECT TO authenticated, anon
USING (bucket_id = 'images');
```

## 🧪 Debugging Steps

### Check Current User Authentication
Run in browser console (on your app):
```javascript
// Check if user is authenticated
const { data: { user } } = await supabase.auth.getUser()
console.log('Current user:', user)
```

### Verify Bucket Exists
```sql
-- Check if images bucket exists
SELECT * FROM storage.buckets WHERE name = 'images';
```

### Check Profile Exists
```sql
-- Check if your profile exists
SELECT * FROM profiles WHERE id = (SELECT auth.uid());
```

## 🎯 Expected Results After Fix

After applying the comprehensive fix:
1. ✅ Upload should work without RLS errors
2. ✅ Images stored in `images` bucket
3. ✅ Posts created successfully in database
4. ✅ No authentication errors

## 🆘 If Problem Persists

1. **Check browser console** for detailed error messages
2. **Verify environment variables** in `.env.local`
3. **Ensure you're using the correct Supabase project**
4. **Check Supabase project URL** matches your configuration

### Common Environment Issues
Verify these variables in `.env.local`:
```
NEXT_PUBLIC_SUPABASE_URL=https://ufkrpnudqproxnyhsild.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 📞 Final Verification

Test the complete flow:
1. ✅ Register/Login works
2. ✅ Profile is created automatically
3. ✅ Image upload succeeds
4. ✅ Post appears in feed
5. ✅ No console errors

The comprehensive RLS fix follows the project's policy management workflow and should resolve all storage-related RLS violations.