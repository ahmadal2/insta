'use client'

import { useEffect } from 'react'
import { supabase } from '@/lib/supabaseClient'

export default function AuthHandler() {
  useEffect(() => {
    // Listen for auth state changes to handle email confirmation
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        if (event === 'SIGNED_IN' && session?.user) {
          // Check if user has a profile
          const { data: profile } = await supabase
            .from('profiles')
            .select('id')
            .eq('id', session.user.id)
            .single()

          // Create profile if it doesn't exist (for email confirmed users)
          if (!profile && session.user.email_confirmed_at) {
            const username = session.user.user_metadata?.username || 
                           session.user.email?.split('@')[0] || 
                           'user'
            
            await supabase
              .from('profiles')
              .insert([
                {
                  id: session.user.id,
                  username: username,
                  avatar_url: null,
                  updated_at: new Date().toISOString(),
                },
              ])
          }
        }
      }
    )

    return () => subscription.unsubscribe()
  }, [])

  return null
}