'use client'

import { useState, useEffect } from 'react'
import { User } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabaseClient'
import { RefreshCw, CheckCircle, XCircle, AlertTriangle } from 'lucide-react'

interface DebugInfo {
  user: User | null
  profile: any
  canUploadToStorage: boolean
  canInsertPost: boolean
  storageErrors: string[]
  databaseErrors: string[]
}

export default function DebugPage() {
  const [debugInfo, setDebugInfo] = useState<DebugInfo | null>(null)
  const [loading, setLoading] = useState(false)

  const runDiagnostics = async () => {
    setLoading(true)
    const errors: string[] = []
    const storageErrors: string[] = []
    const databaseErrors: string[] = []

    try {
      // Check authentication
      const { data: { user }, error: userError } = await supabase.auth.getUser()
      console.log('Auth check:', { user, userError })

      // Check profile
      let profile = null
      if (user) {
        const { data: profileData, error: profileError } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single()
        
        profile = profileData
        if (profileError) {
          console.log('Profile error:', profileError)
        }
      }

      // Test storage upload capability
      let canUploadToStorage = false
      if (user) {
        try {
          // Test with a tiny file
          const testFile = new File(['test'], 'test.txt', { type: 'text/plain' })
          const { error: uploadError } = await supabase.storage
            .from('images')
            .upload(`test-${Date.now()}.txt`, testFile)

          if (uploadError) {
            storageErrors.push(uploadError.message)
            canUploadToStorage = false
          } else {
            canUploadToStorage = true
          }
        } catch (err) {
          storageErrors.push(err instanceof Error ? err.message : 'Unknown storage error')
        }
      }

      // Test database insert capability
      let canInsertPost = false
      if (user) {
        try {
          // Test post insertion (we'll delete it immediately)
          const { data: testPost, error: insertError } = await supabase
            .from('posts')
            .insert({
              image_url: 'https://test.com/test.jpg',
              caption: 'Debug test post'
            })
            .select()

          if (insertError) {
            databaseErrors.push(insertError.message)
            canInsertPost = false
          } else {
            canInsertPost = true
            // Clean up test post
            if (testPost && testPost[0]) {
              await supabase
                .from('posts')
                .delete()
                .eq('id', testPost[0].id)
            }
          }
        } catch (err) {
          databaseErrors.push(err instanceof Error ? err.message : 'Unknown database error')
        }
      }

      setDebugInfo({
        user,
        profile,
        canUploadToStorage,
        canInsertPost,
        storageErrors,
        databaseErrors
      })

    } catch (error) {
      console.error('Debug error:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    runDiagnostics()
  }, [])

  const StatusIcon = ({ status }: { status: boolean | null }) => {
    if (status === null) return <AlertTriangle className="h-5 w-5 text-yellow-500" />
    return status ? 
      <CheckCircle className="h-5 w-5 text-green-500" /> : 
      <XCircle className="h-5 w-5 text-red-500" />
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-4xl mx-auto">
        <div className="bg-white rounded-lg shadow-sm p-6">
          <div className="flex items-center justify-between mb-6">
            <h1 className="text-2xl font-bold">Upload Debug Page</h1>
            <button
              onClick={runDiagnostics}
              disabled={loading}
              className="flex items-center space-x-2 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50"
            >
              <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
              <span>Run Diagnostics</span>
            </button>
          </div>

          {debugInfo && (
            <div className="space-y-6">
              {/* Authentication Status */}
              <div className="border rounded-lg p-4">
                <h2 className="text-lg font-semibold mb-3 flex items-center space-x-2">
                  <StatusIcon status={!!debugInfo.user} />
                  <span>Authentication Status</span>
                </h2>
                <div className="space-y-2 text-sm">
                  <p><strong>User ID:</strong> {debugInfo.user?.id || 'Not logged in'}</p>
                  <p><strong>Email:</strong> {debugInfo.user?.email || 'N/A'}</p>
                  <p><strong>Email Confirmed:</strong> {debugInfo.user?.email_confirmed_at ? 'Yes' : 'No'}</p>
                </div>
              </div>

              {/* Profile Status */}
              <div className="border rounded-lg p-4">
                <h2 className="text-lg font-semibold mb-3 flex items-center space-x-2">
                  <StatusIcon status={!!debugInfo.profile} />
                  <span>Profile Status</span>
                </h2>
                <div className="space-y-2 text-sm">
                  <p><strong>Profile Exists:</strong> {debugInfo.profile ? 'Yes' : 'No'}</p>
                  <p><strong>Username:</strong> {debugInfo.profile?.username || 'N/A'}</p>
                  <p><strong>Created:</strong> {debugInfo.profile?.updated_at || 'N/A'}</p>
                </div>
              </div>

              {/* Storage Test */}
              <div className="border rounded-lg p-4">
                <h2 className="text-lg font-semibold mb-3 flex items-center space-x-2">
                  <StatusIcon status={debugInfo.canUploadToStorage} />
                  <span>Storage Upload Test</span>
                </h2>
                <div className="space-y-2 text-sm">
                  <p><strong>Can Upload:</strong> {debugInfo.canUploadToStorage ? 'Yes' : 'No'}</p>
                  {debugInfo.storageErrors.length > 0 && (
                    <div className="bg-red-50 border border-red-200 rounded p-2">
                      <p className="font-medium text-red-800">Storage Errors:</p>
                      {debugInfo.storageErrors.map((error, index) => (
                        <p key={index} className="text-red-700">{error}</p>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              {/* Database Test */}
              <div className="border rounded-lg p-4">
                <h2 className="text-lg font-semibold mb-3 flex items-center space-x-2">
                  <StatusIcon status={debugInfo.canInsertPost} />
                  <span>Database Insert Test</span>
                </h2>
                <div className="space-y-2 text-sm">
                  <p><strong>Can Insert Posts:</strong> {debugInfo.canInsertPost ? 'Yes' : 'No'}</p>
                  {debugInfo.databaseErrors.length > 0 && (
                    <div className="bg-red-50 border border-red-200 rounded p-2">
                      <p className="font-medium text-red-800">Database Errors:</p>
                      {debugInfo.databaseErrors.map((error, index) => (
                        <p key={index} className="text-red-700">{error}</p>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              {/* Recommendations */}
              <div className="border rounded-lg p-4 bg-blue-50">
                <h2 className="text-lg font-semibold mb-3">Recommendations</h2>
                <div className="space-y-2 text-sm">
                  {!debugInfo.user && (
                    <p className="text-blue-800">• Please log in to test upload functionality</p>
                  )}
                  {!debugInfo.profile && debugInfo.user && (
                    <p className="text-blue-800">• Profile missing - execute the enhanced_storage_fix.sql script</p>
                  )}
                  {!debugInfo.canUploadToStorage && (
                    <p className="text-blue-800">• Storage upload failed - check if 'images' bucket exists and is public</p>
                  )}
                  {!debugInfo.canInsertPost && (
                    <p className="text-blue-800">• Database insert failed - execute enhanced_storage_fix.sql to fix RLS policies</p>
                  )}
                  {debugInfo.canUploadToStorage && debugInfo.canInsertPost && (
                    <p className="text-green-800">• All systems working! Upload should function properly.</p>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}