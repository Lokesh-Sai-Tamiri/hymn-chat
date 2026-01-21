-- ============================================================================
-- PROFILES PUBLIC VIEW POLICY
-- ============================================================================
-- 
-- This migration adds the ability for authenticated users to view other
-- users' PUBLIC profile information for the contacts/networking feature.
-- 
-- HIPAA Compliance:
-- - Only completed profiles are visible to others
-- - Users control visibility by completing their profile
-- - Sensitive data (full address, phone, email) should only be shared
--   between connected users (handled in app layer)
-- ============================================================================

-- Add policy: Authenticated users can view completed profiles
-- This allows the contacts feature to show other doctors
CREATE POLICY "Authenticated users can view completed profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can always see their own profile
    auth.uid() = id
    OR
    -- Users can see other profiles that are marked as completed
    profile_completed = true
  );

-- Note: If you get an error about policy already existing, 
-- you may need to drop the old restrictive policy first:
-- DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run this to verify the policy was created:
-- SELECT * FROM pg_policies WHERE tablename = 'profiles';
