'use client'

import { useEffect, useState } from 'react'
import { User } from '@supabase/supabase-js'
import { supabase, Post } from '@/lib/supabaseClient'
import { getPublicFeed, getFollowingFeed } from '@/lib/postActions'
import PostCard from '@/components/PostCard'
import { Camera, Loader2, Plus, Globe, Users } from 'lucide-react'
import Link from 'next/link'

export default function Home() {
  const [posts, setPosts] = useState<Post[]>([])
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [feedType, setFeedType] = useState<'public' | 'following'>('public')

  const fetchPosts = async (type: 'public' | 'following' = 'public') => {
    try {
      console.log(`Fe
        tching ${type} feed...`)
      
      let postsData
      if (type === 'following' && user) {
        // Try to get following feed first
        try {
          postsData = await getFollowingFeed(20, 0)
        } catch (followingError) {
          console.warn('Following feed failed, falling back to public:', followingError)
          postsData = await getPublicFeed(20, 0)
        }
      } else {
        // Fallback to manual enrichment if advanced functions fail
        try {
          postsData = await getPublicFeed(20, 0)
        } catch (publicError) {
          console.warn('Public feed function failed, using manual method:', publicError)
          
          // Manual fallback - same as before
          const { data: basicPosts, error } = await supabase
            .from('posts')
            .select('*')
            .order('created_at', { ascending: false })

          if (error) {
            console.error('Error fetching posts:', error)
            return
          }

          if (basicPosts && basicPosts.length > 0) {
            const enrichedPosts = await Promise.all(
              basicPosts.map(async (post) => {
                // Get profile for this post's user
                const { data: profile } = await supabase
                  .from('profiles')
                  .select('username, avatar_url')
                  .eq('id', post.user_id)
                  .single()

                // Get likes for this post
                const { data: likes } = await supabase
                  .from('likes')
                  .select('*')
                  .eq('post_id', post.id)

                // Get comments for this post
                const { data: comments } = await supabase
                  .from('comments')
                  .select('*, profiles(username, avatar_url)')
                  .eq('post_id', post.id)
                  .order('created_at', { ascending: true })

                // Get reposts for this post
                const { data: reposts } = await supabase
                  .from('reposts')
                  .select('*')
                  .eq('original_post_id', post.id)

                return {
                  ...post,
                  profiles: profile || { username: 'Unknown', avatar_url: null },
                  likes: likes || [],
                  comments: comments || [],
                  reposts: reposts || []
                }
              })
            )
            
            postsData = enrichedPosts
          } else {
            postsData = basicPosts || []
          }
        }
      }

      console.log('Posts fetched successfully:', postsData)
      setPosts(postsData as Post[])
    } catch (err) {
      console.error('Unexpected error in fetchPosts:', err)
      setPosts([])
    }
  }

  useEffect(() => {
    const getSessionAndPosts = async () => {
      try {
        // Get current user session
        const { data: { session } } = await supabase.auth.getSession()
        setUser(session?.user ?? null)

        // Fetch posts based on current feed type
        await fetchPosts(feedType)
      } catch (err) {
        console.error('Unexpected error in getSessionAndPosts:', err)
      }

      setLoading(false)
    }

    getSessionAndPosts()

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event, session) => {
        setUser(session?.user ?? null)
      }
    )

    return () => subscription.unsubscribe()
  }, [feedType])

  // Effect to refetch posts when feed type changes
  useEffect(() => {
    if (!loading && user) {
      fetchPosts(feedType)
    }
  }, [feedType, user])

  const handleFeedSwitch = (type: 'public' | 'following') => {
    setFeedType(type)
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-2xl mx-auto py-8 px-4">
        {/* Welcome Section */}
        {!user && (
          <div className="bg-white rounded-lg p-8 mb-8 text-center shadow-sm">
            <Camera className="h-16 w-16 text-blue-500 mx-auto mb-4" />
            <h1 className="text-3xl font-bold text-gray-900 mb-2">
              Welcome to AhmadInsta
            </h1>
            <p className="text-gray-600 mb-6">
              Share your moments with the world
            </p>
            <div className="flex justify-center space-x-4">
              <Link
                href="/auth/login"
                className="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
              >
                Sign In
              </Link>
              <Link
                href="/auth/register"
                className="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              >
                Sign Up
              </Link>
            </div>
          </div>
        )}

        {/* Feed Type Switcher for logged in users */}
        {user && (
          <div className="bg-white rounded-lg p-2 mb-6 shadow-sm">
            <div className="flex space-x-2">
              <button
                onClick={() => handleFeedSwitch('public')}
                className={`flex items-center space-x-2 px-4 py-2 rounded-lg transition-colors ${
                  feedType === 'public'
                    ? 'bg-blue-500 text-white'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                <Globe className="h-4 w-4" />
                <span>Public Feed</span>
              </button>
              <button
                onClick={() => handleFeedSwitch('following')}
                className={`flex items-center space-x-2 px-4 py-2 rounded-lg transition-colors ${
                  feedType === 'following'
                    ? 'bg-blue-500 text-white'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                <Users className="h-4 w-4" />
                <span>Following</span>
              </button>
            </div>
          </div>
        )}

        {/* Create Post Button for logged in users */}
        {user && (
          <div className="bg-white rounded-lg p-4 mb-6 shadow-sm">
            <Link
              href="/upload"
              className="flex items-center justify-center space-x-2 w-full py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
            >
              <Plus className="h-5 w-5" />
              <span>Create New Post</span>
            </Link>
          </div>
        )}

        {/* Posts Feed */}
        {posts.length === 0 ? (
          <div className="bg-white rounded-lg p-8 text-center shadow-sm">
            <Camera className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              No posts yet
            </h3>
            <p className="text-gray-600 mb-4">
              Be the first to share a moment!
            </p>
            {user && (
              <Link
                href="/upload"
                className="inline-flex items-center space-x-2 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
              >
                <Plus className="h-4 w-4" />
                <span>Create Post</span>
              </Link>
            )}
          </div>
        ) : (
          <div className="space-y-6">
            {posts.map((post) => (
              <PostCard key={post.id} post={post} currentUser={user} />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
