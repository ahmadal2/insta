'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { supabase } from '@/lib/supabaseClient'
import { Camera, Mail, Lock, User, Loader2 } from 'lucide-react'
import React from 'react'

const registerSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  confirmPassword: z.string(),
  username: z.string().min(3, 'Username must be at least 3 characters'),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ["confirmPassword"],
})

type RegisterFormData = z.infer<typeof registerSchema>

export default function RegisterPage() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | React.ReactElement | null>(null)
  const [success, setSuccess] = useState(false)
  const [needsConfirmation, setNeedsConfirmation] = useState(false)
  const router = useRouter()

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<RegisterFormData>({
    resolver: zodResolver(registerSchema),
  })

  const onSubmit = async (data: RegisterFormData) => {
    setLoading(true)
    setError(null)

    try {
      console.log('Attempting registration with:', data.email)
      
      // Sign up the user
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: data.email,
        password: data.password,
        options: {
          data: {
            username: data.username,
          }
        }
      })

      console.log('Registration response:', { authData, authError })

      if (authError) {
        console.error('Registration error:', authError)
        
        // Handle different types of registration errors
        if (authError.message.includes('User already registered') || 
            authError.message.includes('already been registered') ||
            authError.message.includes('already exists')) {
          setError(
            <div>
              <p className="font-semibold mb-2">This email is already registered!</p>
              <p className="text-sm">Please use a different email address or{' '}
                <Link href="/auth/login" className="text-blue-600 hover:text-blue-500 underline">
                  login with your existing account
                </Link>
              </p>
            </div>
          )
        } else if (authError.message.includes('Password should be at least')) {
          setError('Password must be at least 6 characters long.')
        } else if (authError.message.includes('Unable to validate email')) {
          setError('Please enter a valid email address.')
        } else if (authError.message.includes('rate limit')) {
          setError('Too many registration attempts. Please wait a moment and try again.')
        } else {
          setError(`Registration failed: ${authError.message}`)
        }
        return
      }

      // Check if user was actually created or if it already existed
      if (authData.user) {
        // If user exists but no error was thrown, it might be a duplicate
        if (authData.user.created_at && new Date(authData.user.created_at) < new Date(Date.now() - 1000)) {
          // User was created more than 1 second ago, likely already existed
          setError(
            <div>
              <p className="font-semibold mb-2">This email is already registered!</p>
              <p className="text-sm">Please use a different email address or{' '}
                <Link href="/auth/login" className="text-blue-600 hover:text-blue-500 underline">
                  login with your existing account
                </Link>
              </p>
            </div>
          )
          return
        }

        console.log('User created successfully:', authData.user.id)
        
        // Create profile only if user is confirmed or confirmations are disabled
        if (authData.user.email_confirmed_at || !authData.user.confirmation_sent_at) {
          const { error: profileError } = await supabase
            .from('profiles')
            .insert([
              {
                id: authData.user.id,
                username: data.username,
                avatar_url: null,
                updated_at: new Date().toISOString(),
              },
            ])

          if (profileError) {
            console.error('Error creating profile:', profileError)
          }
        }

        // Check if email confirmation is required
        if (authData.user.confirmation_sent_at && !authData.user.email_confirmed_at) {
          setNeedsConfirmation(true)
          setSuccess(true)
          // Don't redirect, show confirmation message
        } else {
          // User is immediately confirmed, redirect to home
          setNeedsConfirmation(false)
          setSuccess(true)
          setTimeout(() => {
            window.location.href = '/'
          }, 2000)
        }
      } else {
        // No user returned and no error - something went wrong
        setError('Registration failed. Please try again with a different email address.')
      }
    } catch (err) {
      console.error('Registration error:', err)
      setError('An unexpected error occurred. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-md w-full space-y-8 text-center">
          <div>
            <Camera className="h-12 w-12 text-green-500 mx-auto" />
            <h2 className="mt-6 text-3xl font-extrabold text-gray-900">
              {needsConfirmation ? 'Check Your Email!' : 'Registration Successful!'}
            </h2>
            <p className="mt-2 text-sm text-gray-600">
              {needsConfirmation 
                ? 'We sent you a confirmation email. Please click the link in your email to complete registration, then you can login.'
                : 'Welcome to AhmadInsta! Redirecting you to the feed...'
              }
            </p>
            {needsConfirmation && (
              <div className="mt-6">
                <Link
                  href="/auth/login"
                  className="text-blue-600 hover:text-blue-500 font-medium"
                >
                  Go to Login Page
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <div className="flex justify-center">
            <Camera className="h-12 w-12 text-blue-500" />
          </div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Join AhmadInsta
          </h2>
        </div>
        
        <form className="mt-8 space-y-6" onSubmit={handleSubmit(onSubmit)}>
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-md">
              {typeof error === 'string' ? error : error}
            </div>
          )}

          <div className="space-y-4">
            <div>
              <label htmlFor="username" className="block text-sm font-medium text-gray-700">
                Username
              </label>
              <div className="mt-1 relative">
                <User className="absolute left-3 top-3 h-5 w-5 text-gray-400" />
                <input
                  {...register('username')}
                  type="text"
                  className="appearance-none block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  placeholder="Choose a username"
                />
              </div>
              {errors.username && (
                <p className="mt-1 text-sm text-red-600">{errors.username.message}</p>
              )}
            </div>

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                Email address
              </label>
              <div className="mt-1 relative">
                <Mail className="absolute left-3 top-3 h-5 w-5 text-gray-400" />
                <input
                  {...register('email')}
                  type="email"
                  className="appearance-none block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  placeholder="Enter your email"
                />
              </div>
              {errors.email && (
                <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>
              )}
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                Password
              </label>
              <div className="mt-1 relative">
                <Lock className="absolute left-3 top-3 h-5 w-5 text-gray-400" />
                <input
                  {...register('password')}
                  type="password"
                  className="appearance-none block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  placeholder="Choose a password"
                />
              </div>
              {errors.password && (
                <p className="mt-1 text-sm text-red-600">{errors.password.message}</p>
              )}
            </div>

            <div>
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700">
                Confirm Password
              </label>
              <div className="mt-1 relative">
                <Lock className="absolute left-3 top-3 h-5 w-5 text-gray-400" />
                <input
                  {...register('confirmPassword')}
                  type="password"
                  className="appearance-none block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  placeholder="Confirm your password"
                />
              </div>
              {errors.confirmPassword && (
                <p className="mt-1 text-sm text-red-600">{errors.confirmPassword.message}</p>
              )}
            </div>
          </div>

          <div>
            <button
              type="submit"
              disabled={loading}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {loading ? (
                <Loader2 className="h-5 w-5 animate-spin" />
              ) : (
                'Create Account'
              )}
            </button>
          </div>

          <div className="text-center">
            <span className="text-sm text-gray-600">
              Already have an account?{' '}
              <Link href="/auth/login" className="font-medium text-blue-600 hover:text-blue-500">
                Sign in
              </Link>
            </span>
          </div>
        </form>
      </div>
    </div>
  )
}