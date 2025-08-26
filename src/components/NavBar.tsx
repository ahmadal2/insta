'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { User } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabaseClient'
import { Camera, Home, Plus, User as UserIcon, LogOut, LogIn, Bug } from 'lucide-react'

export default function NavBar() {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const router = useRouter()

  useEffect(() => {
    // Get initial session
    const getSession = async () => {
      const { data: { session } } = await supabase.auth.getSession()
      setUser(session?.user ?? null)
      setLoading(false)
    }

    getSession()

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event, session) => {
        setUser(session?.user ?? null)
        setLoading(false)
      }
    )

    return () => subscription.unsubscribe()
  }, [])

  const handleSignOut = async () => {
    await supabase.auth.signOut()
    // Force page refresh to ensure clean state
    window.location.href = '/'
  }

  if (loading) {
    return (
      <nav className="bg-white border-b border-gray-200 px-4 py-3">
        <div className="max-w-4xl mx-auto flex justify-between items-center">
          <div className="animate-pulse h-8 w-32 bg-gray-200 rounded"></div>
        </div>
      </nav>
    )
  }

  return (
    <nav className="bg-white border-b border-gray-200 px-4 py-3 sticky top-0 z-50">
      <div className="max-w-4xl mx-auto flex justify-between items-center">
        {/* Logo */}
        <Link href="/" className="flex items-center space-x-2">
          <Camera className="h-8 w-8" />
          <span className="text-xl font-bold">AhmadInsta</span>
        </Link>

        {/* Navigation Links */}
        <div className="flex items-center space-x-6">
          <Link href="/" className="p-2 hover:bg-gray-100 rounded-full">
            <Home className="h-6 w-6" />
          </Link>
          
          {user ? (
            <>
              <Link href="/upload" className="p-2 hover:bg-gray-100 rounded-full">
                <Plus className="h-6 w-6" />
              </Link>
              <Link href={`/profile/${user.id}`} className="p-2 hover:bg-gray-100 rounded-full">
                <UserIcon className="h-6 w-6" />
              </Link>
              <Link href="/debug" className="p-2 hover:bg-gray-100 rounded-full" title="Debug RLS">
                <Bug className="h-5 w-5 text-gray-600" />
              </Link>
              <button
                onClick={handleSignOut}
                className="p-2 hover:bg-gray-100 rounded-full"
              >
                <LogOut className="h-6 w-6" />
              </button>
            </>
          ) : (
            <>
              <Link href="/debug" className="p-2 hover:bg-gray-100 rounded-full" title="Debug RLS">
                <Bug className="h-5 w-5 text-gray-600" />
              </Link>
              <Link href="/auth/login" className="flex items-center space-x-2 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600">
                <LogIn className="h-4 w-4" />
                <span>Login</span>
              </Link>
            </>
          )}
        </div>
      </div>
    </nav>
  )
}