-- ============================================================================
-- SUPABASE DATABASE SETUP - HymnChat
-- ============================================================================
-- Run this SQL in your Supabase SQL Editor
-- Go to: Supabase Dashboard → SQL Editor → New Query → Paste & Run
-- ============================================================================

-- Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  
  -- Basic Info
  first_name TEXT,
  last_name TEXT,
  display_name TEXT,
  email TEXT,
  phone TEXT,
  
  -- Professional Info (for doctors/medical professionals)
  doctor_id TEXT UNIQUE,
  specialization TEXT,
  clinic_name TEXT,
  years_of_experience INTEGER,
  
  -- Address
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT,
  state TEXT,
  postal_code TEXT,
  country TEXT DEFAULT 'India',
  
  -- Profile
  avatar_url TEXT,
  bio TEXT,
  
  -- Metadata
  profile_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS profiles_doctor_id_idx ON public.profiles(doctor_id);
CREATE INDEX IF NOT EXISTS profiles_email_idx ON public.profiles(email);
CREATE INDEX IF NOT EXISTS profiles_phone_idx ON public.profiles(phone);
CREATE INDEX IF NOT EXISTS profiles_profile_completed_idx ON public.profiles(profile_completed);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Create function to auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, phone, email)
  VALUES (
    NEW.id,
    NEW.phone,
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run these queries to verify setup:

-- Check if table exists
SELECT * FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'profiles';

-- Check policies
SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- Check triggers
SELECT * FROM pg_trigger WHERE tgname LIKE '%profile%';

-- ============================================================================
-- SUCCESS! Your database is ready for HymnChat profiles 🎉
-- ============================================================================

