'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabaseClient'
import { LogIn, LogOut, Loader2 } from 'lucide-react'

interface AuthButtonProps {
  user?: any
  className?: string
}

export default function AuthButton({ user, className = '' }: AuthButtonProps) {
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  const handleSignOut = async () => {
    setLoading(true)
    try {
      await supabase.auth.signOut()
      router.push('/')
    } catch (error) {
      console.error('Error signing out:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSignIn = () => {
    router.push('/auth/login')
  }

  if (user) {
    return (
      <button
        onClick={handleSignOut}
        disabled={loading}
        className={`flex items-center space-x-2 px-4 py-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors ${className}`}
      >
        {loading ? (
          <Loader2 className="h-4 w-4 animate-spin" />
        ) : (
          <LogOut className="h-4 w-4" />
        )}
        <span>{loading ? 'Logging out...' : 'Logout'}</span>
      </button>
    )
  }

  return (
    <button
      onClick={handleSignIn}
      className={`flex items-center space-x-2 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors ${className}`}
    >
      <LogIn className="h-4 w-4" />
      <span>Login</span>
    </button>
  )
}