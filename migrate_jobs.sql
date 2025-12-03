-- Migration Script: Assign Existing Jobs to First User
-- 
-- INSTRUCTIONS:
-- 1. First, create your user account in Supabase Auth Dashboard:
--    - Go to Authentication > Users
--    - Click "Add User"
--    - Enter your email and password
--    - Copy the user's UUID from the table
--
-- 2. Replace 'YOUR_USER_ID_HERE' below with your actual user UUID
--
-- 3. Run this script in Supabase SQL Editor

-- Add user_id column if it doesn't exist (should already exist from schema update)
ALTER TABLE public.jobs 
ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;

-- Update all existing jobs to belong to the first user
-- REPLACE 'YOUR_USER_ID_HERE' with your actual user UUID
UPDATE public.jobs
SET user_id = 'YOUR_USER_ID_HERE'
WHERE user_id IS NULL;

-- Verify the migration
SELECT 
  COUNT(*) as total_jobs,
  user_id
FROM public.jobs
GROUP BY user_id;

-- Expected result: All jobs should now have your user_id
