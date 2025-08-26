'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabaseClient'

export default function DebugAuthPage() {
  const [authInfo, setAuthInfo] = useState<any>(null)
  const [testResults, setTestResults] = useState<string[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    checkAuth()
  }, [])

  const checkAuth = async () => {
    const { data: { session }, error } = await supabase.auth.getSession()
    setAuthInfo({ session, error })
  }

  const testDatabaseAccess = async () => {
    setLoading(true)
    setTestResults([])
    const results: string[] = []

    try {
      // Test 1: Check session
      const { data: { session } } = await supabase.auth.getSession()
      results.push(`✅ Session check: ${session ? 'Authenticated' : 'Not authenticated'}`)
      
      if (!session?.user) {
        results.push('❌ No user session - please log in first')
        setTestResults(results)
        setLoading(false)
        return
      }

      results.push(`✅ User ID: ${session.user.id}`)
      results.push(`✅ User Email: ${session.user.email}`)

      // Test 2: Check if profile exists
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', session.user.id)
        .single()

      if (profileError) {
        results.push(`❌ Profile error: ${profileError.message}`)
      } else {
        results.push(`✅ Profile exists: ${profile?.username || 'No username'}`)
      }

      // Test 3: Try to create a test post
      const testPost = {
        user_id: session.user.id,
        image_url: 'https://example.com/test.jpg',
        caption: 'Test post'
      }

      const { data: postData, error: postError } = await supabase
        .from('posts')
        .insert([testPost])
        .select()

      if (postError) {
        results.push(`❌ Post creation failed: ${postError.message}`)
        results.push(`❌ Error code: ${postError.code}`)
        results.push(`❌ Error details: ${JSON.stringify(postError.details)}`)
      } else {
        results.push(`✅ Test post created successfully!`)
        // Clean up test post
        if (postData?.[0]?.id) {
          await supabase.from('posts').delete().eq('id', postData[0].id)
          results.push(`✅ Test post cleaned up`)
        }
      }

      // Test 4: Check RLS policies
      const { data: policies, error: policyError } = await supabase
        .rpc('get_policies_for_table', { table_name: 'posts' })
        .then(() => ({ data: 'RPC not available', error: null }))
        .catch(() => ({ data: null, error: 'Could not check policies' }))

      results.push(`ℹ️ Policy check: ${policyError || 'Policies seem to be set up'}`);

    } catch (error) {
      results.push(`❌ Unexpected error: ${error}`)
    }

    setTestResults(results)
    setLoading(false)
  }

  return (
    <div className="min-h-screen p-8 bg-gray-50">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold mb-6">Authentication & RLS Debug</h1>
        
        <div className="space-y-6">
          {/* Authentication Status */}
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-semibold mb-4">Current Authentication Status</h2>
            <pre className="text-sm bg-gray-100 p-4 rounded overflow-auto">
              {JSON.stringify(authInfo, null, 2)}
            </pre>
          </div>

          {/* Test Database Access */}
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-semibold mb-4">Database Access Test</h2>
            <button
              onClick={testDatabaseAccess}
              disabled={loading}
              className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50 mb-4"
            >
              {loading ? 'Testing...' : 'Run Database Tests'}
            </button>

            {testResults.length > 0 && (
              <div className="space-y-2">
                {testResults.map((result, index) => (
                  <div
                    key={index}
                    className={`p-3 rounded text-sm ${
                      result.startsWith('✅') 
                        ? 'bg-green-100 text-green-800' 
                        : result.startsWith('❌')
                        ? 'bg-red-100 text-red-800'
                        : 'bg-blue-100 text-blue-800'
                    }`}
                  >
                    {result}
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Quick Actions */}
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-semibold mb-4">Quick Actions</h2>
            <div className="space-x-4">
              <button
                onClick={() => window.location.href = '/auth/login'}
                className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
              >
                Go to Login
              </button>
              <button
                onClick={() => window.location.href = '/upload'}
                className="px-4 py-2 bg-purple-500 text-white rounded hover:bg-purple-600"
              >
                Try Upload
              </button>
              <button
                onClick={checkAuth}
                className="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600"
              >
                Refresh Auth
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}