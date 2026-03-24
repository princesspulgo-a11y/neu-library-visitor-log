-- ENABLE REAL-TIME FOR DELETE OPERATIONS
-- This ensures the dashboard updates immediately when Ceng is deleted=

-- STEP 1: ENABLE REPLICA IDENTITY FULL (REQUIRED FOR DELETE EVENTS)

ALTER TABLE visit_logs REPLICA IDENTITY FULL;
ALTER TABLE visitors REPLICA IDENTITY FULL;
ALTER TABLE profiles REPLICA IDENTITY FULL;

-- Verify replica identity is set to FULL
SELECT 
  schemaname,
  tablename,
  CASE 
    WHEN replica_identity = 'f' THEN '✅ FULL (DELETE events work)'
    WHEN replica_identity = 'd' THEN '⚠️ DEFAULT (DELETE events limited)'
    ELSE '❌ NOTHING (DELETE events broken)'
  END as realtime_status
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
WHERE tablename IN ('visit_logs', 'visitors', 'profiles')
  AND schemaname = 'public';

-- STEP 2: VERIFY REALTIME IS ENABLED IN SUPABASE DASHBOARD
-- Go to: Database → Replication
-- Ensure these tables have replication enabled:
-- ✅ visit_logs
-- ✅ visitors
-- ✅ profiles

-- STEP 3: DELETE CENG CORPEZ AND FORCE REFRESH
DELETE FROM visit_logs
WHERE visitor_id = (SELECT id FROM visitors WHERE email = 'ceng.corpez@neu.edu.ph');

DELETE FROM visitors WHERE email = 'ceng.corpez@neu.edu.ph';
DELETE FROM profiles WHERE email = 'ceng.corpez@neu.edu.ph';
DELETE FROM auth.users WHERE email = 'ceng.corpez@neu.edu.ph';

-- STEP 4: VERIFY CENG CORPEZ IS GONE
SELECT 
  (SELECT COUNT(*) FROM visit_logs WHERE visitor_id IN (SELECT id FROM visitors WHERE email = 'ceng.corpez@neu.edu.ph')) as logs,
  (SELECT COUNT(*) FROM visitors WHERE email = 'ceng.corpez@neu.edu.ph') as visitor,
  (SELECT COUNT(*) FROM profiles WHERE email = 'ceng.corpez@neu.edu.ph') as profile,
  (SELECT COUNT(*) FROM auth.users WHERE email = 'ceng.corpez@neu.edu.ph') as auth;
-- All should be 0

-- STEP 5: CHECK CURRENT "INSIDE" COUNT
SELECT COUNT(*) as currently_inside
FROM visit_logs
WHERE time_out IS NULL;

-- TROUBLESHOOTING: IF DASHBOARD STILL SHOWS CENG CORPEZ

-- Option 1: Hard refresh the browser
-- Ctrl + Shift + R (Windows) / Cmd + Shift + R (Mac)

-- Option 2: Clear browser cache
-- F12 → Application → Clear Storage → Clear site data

-- Option 3: Check Realtime connection in console
-- Look for:
-- "Realtime subscribed: visit_logs"
-- "Realtime subscribed: visitors"

-- Option 4: Trigger dummy update
UPDATE visit_logs
SET duration_minutes = duration_minutes
WHERE id = (SELECT id FROM visit_logs ORDER BY time_in DESC LIMIT 1);

-- STEP 6: TEST REALTIME IS WORKING

UPDATE visit_logs
SET duration_minutes = 999
WHERE id = (SELECT id FROM visit_logs ORDER BY time_in DESC LIMIT 1);

-- Reset test
UPDATE visit_logs
SET duration_minutes = EXTRACT(EPOCH FROM (time_out - time_in)) / 60
WHERE duration_minutes = 999;

-- SUCCESS CRITERIA
-- ✅ Ceng Corpez deleted from database
-- ✅ Dashboard updates within 2 seconds
-- ✅ "Currently Inside" count is accurate
-- ✅ Visitor Logs no longer shows Ceng Corpez
-- ✅ User Management no longer shows Ceng Corpez
-- ✅ Realtime is working (console shows subscriptions)
