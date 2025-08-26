'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { supabase } from '@/lib/supabaseClient'
import { Upload, Image as ImageIcon, Loader2, X } from 'lucide-react'
import { v4 as uuidv4 } from 'uuid'

const uploadSchema = z.object({
  caption: z.string().max(500, 'Caption too long').optional(),
})

type UploadFormData = z.infer<typeof uploadSchema>

interface UploadFormProps {
  userId: string
  onSuccess?: () => void
}

export default function UploadForm({ userId, onSuccess }: UploadFormProps) {
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [preview, setPreview] = useState<string | null>(null)
  const [uploading, setUploading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const router = useRouter()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<UploadFormData>({
    resolver: zodResolver(uploadSchema),
  })

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    // Validate file type
    if (!file.type.startsWith('image/')) {
      setError('Please select an image file')
      return
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      setError('File size must be less than 5MB')
      return
    }

    setSelectedFile(file)
    setError(null)

    // Create preview
    const reader = new FileReader()
    reader.onload = (e) => {
      setPreview(e.target?.result as string)
    }
    reader.readAsDataURL(file)
  }

  const removeFile = () => {
    setSelectedFile(null)
    setPreview(null)
    setError(null)
  }

  const onSubmit = async (data: UploadFormData) => {
    if (!selectedFile) {
      setError('Please select an image')
      return
    }

    setUploading(true)
    setError(null)

    try {
      console.log('Starting upload process...')
      
      // Check if user is authenticated using getUser() method
      const { data: { user }, error: userError } = await supabase.auth.getUser()
      if (userError || !user) {
        setError('You must be logged in to upload images. Please log in first.')
        return
      }
      
      console.log('User authenticated:', user.id)
      console.log('User email:', user.email)
      console.log('User email confirmed:', user.email_confirmed_at)
      
      // Check if user has a profile (critical for RLS)
      const { data: profileCheck, error: profileCheckError } = await supabase
        .from('profiles')
        .select('id, username')
        .eq('id', user.id)
        .single()
      
      console.log('Profile check:', { profileCheck, profileCheckError })
      
      if (profileCheckError && profileCheckError.code === 'PGRST116') {
        // No profile found - try to create one
        console.log('No profile found, creating one...')
        const { error: createProfileError } = await supabase
          .from('profiles')
          .insert({
            id: user.id,
            username: user.email?.split('@')[0] || 'user',
            avatar_url: null,
            updated_at: new Date().toISOString()
          })
        
        if (createProfileError) {
          console.error('Failed to create profile:', createProfileError)
          setError('Profile setup failed. Please contact support.')
          return
        }
      }
      
      // Generate unique filename
      const fileExt = selectedFile.name.split('.').pop()
      const fileName = `${uuidv4()}.${fileExt}`
      console.log('Generated filename:', fileName)

      // Upload image to Supabase Storage
      console.log('Attempting to upload to "images" bucket...')
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('images')
        .upload(fileName, selectedFile)

      console.log('Upload response:', { uploadData, uploadError })

      if (uploadError) {
        console.error('Storage upload error:', uploadError)
        
        // Handle specific storage errors
        if (uploadError.message.includes('Bucket not found') || uploadError.message.includes('bucket does not exist')) {
          throw new Error(
            'Storage bucket "images" not found. Please create it in your Supabase Storage dashboard and make it public.'
          )
        }
        
        // Handle Storage RLS policy violations
        if (uploadError.message.includes('row-level security policy') || 
            uploadError.message.includes('new row violates row-level security')) {
          throw new Error(
            'Storage permission denied. The "images" bucket must be configured as PUBLIC in your Supabase Dashboard. Go to Storage → images → Settings → Enable "Public bucket".'
          )
        }
        
        // Handle authentication errors
        if (uploadError.message.includes('JWT') || uploadError.message.includes('authentication')) {
          throw new Error(
            'Authentication error. Please log out and log back in, then try again.'
          )
        }
        
        // Handle policy/permission errors
        if (uploadError.message.includes('policy') || uploadError.message.includes('permission')) {
          throw new Error(
            'Storage access denied. Please ensure the "images" bucket exists and is configured as PUBLIC in Supabase Dashboard.'
          )
        }
        
        throw new Error(`Storage upload failed: ${uploadError.message}`)
      }

      // Get public URL
      const { data: urlData } = supabase.storage
        .from('images')
        .getPublicUrl(fileName)

      if (!urlData?.publicUrl) {
        throw new Error('Failed to get image URL')
      }

      // Create post record - Using DEFAULT auth.uid() approach (Solution 2)
      console.log('Creating post record with simplified approach...')
      
      const { data: postData, error: postError } = await supabase
        .from('posts')
        .insert([
          {
            // user_id is automatically set by database DEFAULT auth.uid()
            image_url: urlData.publicUrl,
            caption: data.caption || null,
          },
        ])
        .select()

      console.log('Post creation response:', { postData, postError })

      if (postError) {
        // Handle specific RLS errors
        if (postError.message.includes('row-level security policy')) {
          throw new Error(
            'Permission denied: You must be logged in and have the proper permissions to create posts. Please log out and log back in.'
          )
        }
        throw postError
      }

      // Reset form
      reset()
      removeFile()
      
      // Call success callback or redirect
      if (onSuccess) {
        onSuccess()
      } else {
        router.push('/')
      }
    } catch (err) {
      console.error('=== DETAILED UPLOAD ERROR ===')
      console.error('Error object:', err)
      console.error('Error type:', typeof err)
      console.error('Error constructor:', err?.constructor?.name)
      console.error('Error message:', err instanceof Error ? err.message : err)
      console.error('Error stack:', err instanceof Error ? err.stack : 'No stack trace')
      console.error('Supabase client status:', !!supabase)
      console.error('Environment check:')
      console.error('- SUPABASE_URL exists:', !!process.env.NEXT_PUBLIC_SUPABASE_URL)
      console.error('- SUPABASE_ANON_KEY exists:', !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY)
      console.error('================================')
      
      // Handle empty error objects and network issues
      let errorMessage = 'Failed to upload image'
      
      if (err instanceof Error) {
        errorMessage = err.message
      } else if (typeof err === 'string') {
        errorMessage = err
      } else if (err && typeof err === 'object') {
        // Handle empty error objects or network errors
        if (Object.keys(err).length === 0) {
          errorMessage = 'Network error or configuration issue. Please check your internet connection and Supabase configuration.'
        } else {
          errorMessage = JSON.stringify(err)
        }
      }
      
      setError(`Upload failed: ${errorMessage}`)
    } finally {
      setUploading(false)
    }
  }

  return (
    <div className="max-w-lg mx-auto">
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        {/* File Upload Area */}
        <div className="space-y-4">
          {!preview ? (
            <div className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-gray-400 transition-colors">
              <input
                type="file"
                accept="image/*"
                onChange={handleFileSelect}
                className="hidden"
                id="file-upload"
              />
              <label
                htmlFor="file-upload"
                className="cursor-pointer flex flex-col items-center space-y-4"
              >
                <Upload className="h-12 w-12 text-gray-400" />
                <div>
                  <p className="text-lg font-medium text-gray-900">
                    Click to upload an image
                  </p>
                  <p className="text-sm text-gray-500">
                    PNG, JPG, GIF up to 5MB
                  </p>
                </div>
              </label>
            </div>
          ) : (
            <div className="relative">
              <img
                src={preview}
                alt="Preview"
                className="w-full h-64 object-cover rounded-lg"
              />
              <button
                type="button"
                onClick={removeFile}
                className="absolute top-2 right-2 p-1 bg-black bg-opacity-50 text-white rounded-full hover:bg-opacity-70"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          )}
        </div>

        {/* Caption Input */}
        <div>
          <label htmlFor="caption" className="block text-sm font-medium text-gray-700 mb-2">
            Caption (optional)
          </label>
          <textarea
            {...register('caption')}
            rows={3}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            placeholder="Write a caption for your post..."
          />
          {errors.caption && (
            <p className="mt-1 text-sm text-red-600">{errors.caption.message}</p>
          )}
        </div>

        {/* Error Message */}
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-md">
            <div className="flex items-start">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3 flex-1">
                <h3 className="text-sm font-medium text-red-800">Upload Error</h3>
                <div className="mt-1 text-sm text-red-700">
                  <p>{error}</p>
                  {error.includes('Storage bucket not found') && (
                    <div className="mt-2 p-3 bg-red-100 rounded border">
                      <p className="font-medium">Quick Fix:</p>
                      <ol className="mt-1 list-decimal list-inside space-y-1 text-xs">
                        <li>Go to your Supabase Dashboard</li>
                        <li>Navigate to Storage section</li>
                        <li>Create a new bucket named "images"</li>
                        <li>Make it public</li>
                        <li>Try uploading again</li>
                      </ol>
                    </div>
                  )}
                  {error.includes('must be logged in') && (
                    <div className="mt-2 p-3 bg-red-100 rounded border">
                      <p className="font-medium">Authentication Required:</p>
                      <p className="mt-1 text-xs">Please log in to your account before uploading images.</p>
                    </div>
                  )}
                  {error.includes('Permission denied') && (
                    <div className="mt-2 p-3 bg-red-100 rounded border">
                      <p className="font-medium">Permission Issue:</p>
                      <ol className="mt-1 list-decimal list-inside space-y-1 text-xs">
                        <li>Try logging out and logging back in</li>
                        <li>Make sure your account is properly confirmed</li>
                        <li>Check if database policies are set up correctly</li>
                      </ol>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Submit Button */}
        <button
          type="submit"
          disabled={!selectedFile || uploading}
          className="w-full flex justify-center items-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {uploading ? (
            <>
              <Loader2 className="h-4 w-4 animate-spin mr-2" />
              Uploading...
            </>
          ) : (
            <>
              <ImageIcon className="h-4 w-4 mr-2" />
              Share Post
            </>
          )}
        </button>
      </form>
    </div>
  )
}