import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Types for our database tables
export interface Profile {
  id: string
  username: string | null
  avatar_url: string | null
  bio: string | null
  updated_at: string
}

export interface Post {
  id: string
  user_id: string
  image_url: string
  caption: string | null
  created_at: string
  profiles: Profile
  likes: Like[]
  comments: Comment[]
  reposts: Repost[]
  likes_count?: number
  comments_count?: number
  reposts_count?: number
}

export interface Like {
  id: string
  post_id: string
  user_id: string
  created_at: string
}

export interface Comment {
  id: string
  post_id: string
  user_id: string
  text: string
  created_at: string
  profiles: Profile
}

export interface Follow {
  follower_id: string
  following_id: string
  created_at: string
}

export interface Repost {
  id: string
  original_post_id: string
  user_id: string
  created_at: string
  profiles?: Profile
  posts?: Post
}

export interface UserStats {
  id: string
  username: string | null
  avatar_url: string | null
  bio: string | null
  posts_count: number
  followers_count: number
  following_count: number
}