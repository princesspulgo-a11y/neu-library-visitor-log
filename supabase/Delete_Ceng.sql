-- DELETE CENG'S DATA
-- This will completely remove Ceng Corpez from the system
-- Run these queries in order in Supabase SQL Editor

-- Step 1: Find Ceng's visitor_id (for verification)
SELECT id, email, full_name, visitor_type, is_blocked
FROM visitors
WHERE email = 'ceng.corpez@neu.edu.ph';

-- Step 2: Delete all Ceng's visit logs
DELETE FROM visit_logs
WHERE visitor_id = (
  SELECT id FROM visitors WHERE email = 'ceng.corpez@neu.edu.ph'
);

-- Step 3: Delete Ceng's visitor record
DELETE FROM visitors
WHERE email = 'ceng.corpez@neu.edu.ph';

-- Step 4: Verify deletion (should return 0 rows)
SELECT * FROM visitors WHERE email = 'ceng.corpez@neu.edu.ph';
SELECT * FROM visit_logs WHERE visitor_id IN (
  SELECT id FROM visitors WHERE email = 'ceng.corpez@neu.edu.ph'
);
-- ALTERNATIVE: Just close all Cengs's active sessions (keep history)
-- If you want to keep Wayne's account but just close duplicate sessions:

UPDATE visit_logs
SET 
  time_out = NOW(),
  duration_minutes = EXTRACT(EPOCH FROM (NOW() - time_in)) / 60
WHERE visitor_id = (SELECT id FROM visitors WHERE email = 'ceng.corpez@neu.edu.ph')
  AND time_out IS NULL;

-- Verify (should return 0 rows)
SELECT * FROM visit_logs 
WHERE visitor_id = (SELECT id FROM visitors WHERE email = 'ceng.corpez@neu.edu.ph')
  AND time_out IS NULL;
