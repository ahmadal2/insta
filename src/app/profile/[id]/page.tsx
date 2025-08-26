'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'
import { User } from '@supabase/supabase-js'
import { supabase, Post, Profile } from '@/lib/supabaseClient'
import { followUser, unfollowUser, checkIfFollowing } from '@/lib/postActions'
import PostCard from '@/components/PostCard'
import { User as UserIcon, Loader2, Grid, UserPlus, UserMinus, Settings } from 'lucide-react'
import Link from 'next/link'

export default function ProfilePage() {
  const params = useParams()
  const userId = params.id as string
  
  const [profile, setProfile] = useState<Profile | null>(null)
  const [posts, setPosts] = useState<Post[]>([])
  const [currentUser, setCurrentUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [isFollowing, setIsFollowing] = useState(false)
  const [followLoading, setFollowLoading] = useState(false)
  const [stats, setStats] = useState({
    postsCount: 0,
    followersCount: 0,
    followingCount: 0
  })

  useEffect(() => {
    const fetchData = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession()
        setCurrentUser(session?.user ?? null)

        // Fetch profile data
        const { data: profileData, error: profileError } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single()

        if (profileError) {
          console.error('Profile fetch error:', profileError)
        } else {
          setProfile(profileData)
        }

        // Fetch posts with simplified query to avoid foreign key issues
        const { data: postsData, error: postsError } = await supabase
          .from('posts')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', { ascending: false })

        if (postsError) {
          console.error('Posts fetch error:', postsError)
          setPosts([]) // Ensure posts is always an array
        } else {
          // If posts exist, fetch additional data for each post
          if (postsData && postsData.length > 0) {
            const enrichedPosts = await Promise.all(
              postsData.map(async (post) => {
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
                  .select('*')
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
            
            setPosts(enrichedPosts as Post[])
          } else {
            setPosts(postsData || []) // Ensure posts is always an array
          }
        }

        // Fetch user statistics
        const { data: followersData } = await supabase
          .from('follows')
          .select('*')
          .eq('following_id', userId)

        const { data: followingData } = await supabase
          .from('follows')
          .select('*')
          .eq('follower_id', userId)

        setStats({
          postsCount: postsData?.length || 0,
          followersCount: followersData?.length || 0,
          followingCount: followingData?.length || 0
        })

        // Check if current user is following this profile
        if (session?.user && session.user.id !== userId) {
          const following = await checkIfFollowing(userId)
          setIsFollowing(following)
        }
      } catch (error) {
        console.error('Error:', error)
        setPosts([]) // Ensure posts is always an array even on error
      } finally {
        setLoading(false)
      }
    }

    if (userId) fetchData()
  }, [userId])

  const handleFollowToggle = async () => {
    if (!currentUser) {
      return
    }

    setFollowLoading(true)
    try {
      if (isFollowing) {
        await unfollowUser(userId)
        setIsFollowing(false)
        setStats(prev => ({ ...prev, followersCount: prev.followersCount - 1 }))
      } else {
        await followUser(userId)
        setIsFollowing(true)
        setStats(prev => ({ ...prev, followersCount: prev.followersCount + 1 }))
      }
    } catch (error) {
      console.error('Error toggling follow:', error)
    } finally {
      setFollowLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
      </div>
    )
  }

  if (!profile) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-2">Profile not found</h1>
          <Link href="/" className="text-blue-500 hover:underline">Go back to feed</Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto py-8 px-4">
        {/* Profile Header */}
        <div className="bg-white rounded-lg p-8 mb-8 shadow-sm">
          <div className="flex items-start space-x-8">
            <div className="w-32 h-32 bg-gray-300 rounded-full flex items-center justify-center">
              {profile.avatar_url ? (
                <img src={profile.avatar_url} alt="Profile" className="w-full h-full rounded-full object-cover" />
              ) : (
                <UserIcon className="w-16 h-16 text-gray-600" />
              )}
            </div>
            <div className="flex-1">
              <div className="flex items-center space-x-4 mb-4">
                <h1 className="text-2xl font-bold">{profile.username || 'Anonymous'}</h1>
                
                {/* Follow/Edit Button */}
                {currentUser && currentUser.id === userId ? (
                  <Link
                    href={`/profile/${userId}/edit`}
                    className="flex items-center space-x-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    <Settings className="h-4 w-4" />
                    <span>Edit Profile</span>
                  </Link>
                ) : currentUser ? (
                  <button
                    onClick={handleFollowToggle}
                    disabled={followLoading}
                    className={`flex items-center space-x-2 px-4 py-2 rounded-lg transition-colors disabled:opacity-50 ${
                      isFollowing
                        ? 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                        : 'bg-blue-500 text-white hover:bg-blue-600'
                    }`}
                  >
                    {followLoading ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : isFollowing ? (
                      <UserMinus className="h-4 w-4" />
                    ) : (
                      <UserPlus className="h-4 w-4" />
                    )}
                    <span>{isFollowing ? 'Unfollow' : 'Follow'}</span>
                  </button>
                ) : null}
              </div>
              
              {/* User Statistics */}
              <div className="flex space-x-8 mb-4">
                <div className="text-center">
                  <div className="text-xl font-bold">{stats.postsCount}</div>
                  <div className="text-gray-600">Posts</div>
                </div>
                <div className="text-center">
                  <div className="text-xl font-bold">{stats.followersCount}</div>
                  <div className="text-gray-600">Followers</div>
                </div>
                <div className="text-center">
                  <div className="text-xl font-bold">{stats.followingCount}</div>
                  <div className="text-gray-600">Following</div>
                </div>
              </div>
              
              {/* Bio */}
              {profile.bio && (
                <p className="text-gray-700">{profile.bio}</p>
              )}
            </div>
          </div>
        </div>

        {/* Posts */}
        <div className="bg-white rounded-lg shadow-sm p-4">
          <h2 className="text-lg font-semibold mb-4">Posts</h2>
          {(!posts || posts.length === 0) ? (
            <div className="text-center py-12">
              <Grid className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-600">No posts yet</p>
            </div>
          ) : (
            <div className="space-y-6">
              {posts.map((post) => (
                <PostCard key={post.id} post={post} currentUser={currentUser} />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}