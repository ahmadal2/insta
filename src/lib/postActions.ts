import { supabase } from './supabaseClient'

/**
 * Helper functions for advanced Instagram-clone features
 * Frontend explicitly sets user_id for all operations (Solution 1)
 */

// POST OPERATIONS
export async function createPost(imageUrl: string, caption?: string) {
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  if (userError || !user) throw new Error('Not logged in!')

  const { data, error } = await supabase.from('posts').insert({
    user_id: user.id,   // 👈 explicit user_id (REQUIRED)
    image_url: imageUrl,
    caption: caption || null
  }).select()

  if (error) throw error
  return data
}

// COMMENT OPERATIONS
export async function addComment(postId: string, text: string) {
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  if (userError || !user) throw new Error('Not logged in!')

  const { data, error } = await supabase.from('comments').insert({
    user_id: user.id,    // 👈 explicit user_id (REQUIRED)
    post_id: postId,
    text: text
  }).select()

  if (error) throw error
  return data
}

export async function deleteComment(commentId: string) {
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  if (userError || !user) throw new Error('Not logged in!')

  const { data, error } = await supabase
    .from('comments')
    .delete()
    .eq('id', commentId)
    .eq('user_id', user.id)  // Extra safety check

  if (error) throw error
  return data
}

// LIKE OPERATIONS
export async function likePost(postId: string) {
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  if (userError || !user) throw new Error('Not logged in!')

  const { data, error } = await supabase.from('likes').insert({
    user_id: user.id,   // 👈 explicit user_id (REQUIRED)
    post_id: postId
  }).select()

  if (error) throw error
  return data
}

export async function unlikePost(postId: string) {
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  if (userError || !user) throw new Error('Not logged in!')

  const { data, error } = await supabase
    .from('likes')
    .delete()
    .eq('user_id', user.id)
    .eq('post_id', postId)

  if (error) throw error
  return data
}

// FOLLOW OPERATIONS (NEW)
export async function followUser(followingId: string) {
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  if (userError || !user) throw new Error('Not logged in!')

  if (user.id === followingId) {
    throw new Error('Cannot follow yourself!')
  }

  const { data, error } = await supabase.from('follows').insert({
    follower_id: user.id,   // 👈 explicit follower_id (REQUIRED)
    following_id: followingId
  }).select()

  if (error) throw error
  return data
}

export async function unfollowUser(followingId: string) {
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  if (userError || !user) throw new Error('Not logged in!')

  const { data, error } = await supabase
    .from('follows')
    .delete()
    .eq('follower_id', user.id)
    .eq('following_id', followingId)

  if (error) throw error
  return data
}

export async function checkIfFollowing(followingId: string): Promise<boolean> {
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  if (userError || !user) return false

  const { data, error } = await supabase
    .from('follows')
    .select('*')
    .eq('follower_id', user.id)
    .eq('following_id', followingId)
    .single()

  return !error && !!data
}

// REPOST OPERATIONS (NEW)
export async function repostPost(originalPostId: string) {
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  if (userError || !user) throw new Error('Not logged in!')

  const { data, error } = await supabase.from('reposts').insert({
    user_id: user.id,           // 👈 explicit user_id (REQUIRED)
    original_post_id: originalPostId
  }).select()

  if (error) throw error
  return data
}

export async function unrepostPost(originalPostId: string) {
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  if (userError || !user) throw new Error('Not logged in!')

  const { data, error } = await supabase
    .from('reposts')
    .delete()
    .eq('user_id', user.id)
    .eq('original_post_id', originalPostId)

  if (error) throw error
  return data
}

export async function checkIfReposted(originalPostId: string): Promise<boolean> {
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  if (userError || !user) return false

  const { data, error } = await supabase
    .from('reposts')
    .select('*')
    .eq('user_id', user.id)
    .eq('original_post_id', originalPostId)
    .single()

  return !error && !!data
}

// USER STATS
export async function getUserStats(userId: string) {
  const { data, error } = await supabase
    .from('user_stats')
    .select('*')
    .eq('id', userId)
    .single()

  if (error) throw error
  return data
}

// FEED OPERATIONS
export async function getFollowingFeed(limit = 20, offset = 0) {
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  if (userError || !user) throw new Error('Not logged in!')

  // Get posts from users I follow + my own posts
  const { data, error } = await supabase
    .from('posts')
    .select(`
      *,
      profiles:user_id (username, avatar_url),
      likes (*),
      comments (*),
      reposts (*)
    `)
    .or(`user_id.eq.${user.id},user_id.in.(${await getFollowingIds(user.id)})`)
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1)

  if (error) throw error
  return data
}

export async function getPublicFeed(limit = 20, offset = 0) {
  const { data, error } = await supabase
    .from('posts')
    .select(`
      *,
      profiles:user_id (username, avatar_url),
      likes (*),
      comments (*),
      reposts (*)
    `)
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1)

  if (error) throw error
  return data
}

// Helper function to get following user IDs
async function getFollowingIds(userId: string): Promise<string> {
  const { data, error } = await supabase
    .from('follows')
    .select('following_id')
    .eq('follower_id', userId)

  if (error || !data || data.length === 0) return ''
  return data.map(f => f.following_id).join(',')
}

/**
 * Alternative functions for Solution 2 approach
 * (Database automatically sets user_id)
 */

/**
 * Enhanced functions using DEFAULT auth.uid() approach (Solution 2)
 * Simplified policies with reduced client-side error surface
 */

export async function createPostSimplified(imageUrl: string, caption?: string) {
  // Check authentication
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  if (userError || !user) throw new Error('Not logged in!')

  // With DEFAULT auth.uid() set, user_id is automatic - no need to pass it
  const { data, error } = await supabase.from('posts').insert({
    image_url: imageUrl,
    caption: caption || null
    // user_id is automatically set by database DEFAULT auth.uid()
  }).select()

  if (error) throw error
  return data
}

export async function createPostAuto(imageUrl: string, caption?: string) {
  // With DEFAULT auth.uid() set, user_id is automatic
  const { data, error } = await supabase.from('posts').insert({
    image_url: imageUrl,
    caption: caption || null
    // user_id is automatically set by database DEFAULT
  }).select()

  if (error) throw error
  return data
}

export async function addCommentAuto(postId: string, text: string) {
  // With DEFAULT auth.uid() set, user_id is automatic
  const { data, error } = await supabase.from('comments').insert({
    post_id: postId,
    text: text
    // user_id is automatically set by database DEFAULT
  }).select()

  if (error) throw error
  return data
}

export async function likePostAuto(postId: string) {
  // With DEFAULT auth.uid() set, user_id is automatic
  const { data, error } = await supabase.from('likes').insert({
    post_id: postId
    // user_id is automatically set by database DEFAULT
  }).select()

  if (error) throw error
  return data
}