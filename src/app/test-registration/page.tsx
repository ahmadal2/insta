'use client'

import { useState } from 'react'
import Link from 'next/link'
import { supabase } from '@/lib/supabaseClient'

export default function TestRegistrationPage() {
  const [testResults, setTestResults] = useState<string[]>([])
  const [loading, setLoading] = useState(false)

  const testExistingEmail = async () => {
    setLoading(true)
    setTestResults([])
    
    try {
      // Try to register with a likely existing email
      const { data, error } = await supabase.auth.signUp({
        email: 'test@example.com',
        password: 'password123',
      })

      const results = []
      results.push(`Test: Register with existing email`)
      results.push(`Response data: ${JSON.stringify(data, null, 2)}`)
      results.push(`Response error: ${JSON.stringify(error, null, 2)}`)
      
      if (error) {
        results.push(`✅ Error detected: ${error.message}`)
        if (error.message.includes('User already registered') || 
            error.message.includes('already been registered') ||
            error.message.includes('already exists')) {
          results.push(`✅ Duplicate email error properly detected`)
        }
      } else if (data.user) {
        results.push(`⚠️ User created or returned: ${data.user.id}`)
      }
      
      setTestResults(results)
    } catch (err) {
      setTestResults([`❌ Unexpected error: ${err}`])
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen p-8 bg-gray-50">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold mb-6">Registration Error Handling Test</h1>
        
        <div className="bg-white p-6 rounded-lg shadow mb-6">
          <h2 className="text-xl font-semibold mb-4">Test Duplicate Email Registration</h2>
          <p className="text-gray-600 mb-4">
            This will test what happens when someone tries to register with an email that already exists.
          </p>
          
          <button
            onClick={testExistingEmail}
            disabled={loading}
            className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50"
          >
            {loading ? 'Testing...' : 'Test Registration with Existing Email'}
          </button>
        </div>

        {testResults.length > 0 && (
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-lg font-semibold mb-4">Test Results:</h3>
            <pre className="text-sm bg-gray-100 p-4 rounded overflow-auto">
              {testResults.join('\n')}
            </pre>
          </div>
        )}

        <div className="mt-6 text-center">
          <Link href="/auth/register" className="text-blue-600 hover:underline">
            → Go to actual registration page
          </Link>
        </div>
      </div>
    </div>
  )
}