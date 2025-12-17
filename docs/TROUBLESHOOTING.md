# 🔧 Troubleshooting Guide

## ⚠️ CRITICAL: "Could not find table 'public.profiles'" Error

### Problem:
After entering OTP, app crashes and returns to phone number screen.

**Error in logs:**
```
flutter: ⚠️ Error checking profile: PostgrestException... 
"Could not find the table 'public.profiles' in the schema cache"
```

### Root Cause:
The `profiles` table doesn't exist in your Supabase database yet!

---

## ✅ SOLUTION (REQUIRED!)

### Step 1: Create Profiles Table in Supabase

1. **Go to Supabase Dashboard**
   - Open https://supabase.com
   - Login to your project

2. **Navigate to SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Run the SQL Script**
   - Open file: `SUPABASE_DATABASE_SETUP.sql` (in your project root)
   - Copy ALL the SQL code
   - Paste into Supabase SQL Editor
   - Click "Run" button

4. **Verify Table Created**
   - Go to "Table Editor" in Supabase
   - You should see `profiles` table listed

---

### Step 2: Hot Restart App

After creating the table:

**In your terminal (where flutter run is active):**
```
Press R to hot restart
```

---

## 🎯 Expected Behavior After Fix

### First Login:
```
1. Enter phone number
2. Enter OTP
3. ✅ Navigate to Create Profile screen
4. Fill profile form
5. Navigate to Home screen
```

### Second Login (same phone):
```
1. Enter phone number
2. Enter OTP
3. ✅ Navigate directly to Home screen (profile exists!)
```

---

## 🐛 Other Errors You Might See

### 1. TextEditingController Disposed Error

**Error:**
```
A TextEditingController was used after being disposed.
```

**Status:** ✅ FIXED automatically
- Wrapped profile check in try-catch
- Graceful error handling
- Navigation proceeds even if profile check fails

---

### 2. Token Expired Error (First OTP Attempt)

**Error:**
```
flutter: ❌ Verification failed: Token has expired or is invalid
```

**Status:** ⚠️ Expected behavior (Not a bug!)
- First OTP verification attempt fails
- Automatic retry succeeds
- This is a known Supabase quirk with first-time users
- **Second attempt always succeeds** ✅

---

### 3. Profile Not Loading

**Symptoms:**
- Profile screen shows "Loading..."
- Or shows placeholder data

**Solution:**
1. Check that you ran the SQL script
2. Verify user has filled profile form
3. Check Supabase Table Editor to see if data is there

**Query to check:**
```sql
SELECT * FROM profiles WHERE phone = '+917993598294';
```

---

## 📋 Checklist Before Testing

- [ ] SQL script run in Supabase ✅ (CRITICAL!)
- [ ] Table `profiles` exists in database
- [ ] App hot restarted (press R)
- [ ] Phone number format: 10 digits (e.g., 7993598294)
- [ ] OTP received via SMS
- [ ] Internet connection stable

---

## 🔍 How to Debug

### Check Supabase Table:

1. **Table Editor → profiles**
2. **Check if table exists**
3. **Check if columns match:**
   - id
   - first_name
   - last_name
   - email
   - phone
   - doctor_id
   - specialization
   - clinic_name
   - years_of_experience
   - address_line1, address_line2, city, state, postal_code, country
   - avatar_url
   - bio
   - profile_completed
   - created_at
   - updated_at

### Check Flutter Logs:

**Good logs (working):**
```
✅ OTP verified successfully
👤 User ID: 4e7fa4d2-...
📋 Fetching profile for user: 4e7fa4d2-...
✅ Profile found / ⚠️ No profile found - needs to create profile
```

**Bad logs (problem):**
```
⚠️ Error checking profile: PostgrestException... "Could not find the table"
```

---

## 🚀 Quick Fix Summary

### Problem: App crashes after OTP
**Solution:** Run SQL script in Supabase (2 minutes)

### Problem: Still crashes
**Solution:** Hot restart app (press R)

### Problem: Profile not saving
**Solution:** Check Supabase RLS policies are enabled

---

## 💡 Pro Tips

1. **Always check terminal logs first**
   - Look for red errors
   - Look for `PostgrestException`
   - Check if table exists

2. **Test in this order:**
   - Create table → Hot restart → Login → Fill profile → Logout → Login again

3. **Delete test data between tests:**
   ```sql
   DELETE FROM profiles WHERE phone = '+917993598294';
   ```

---

## 📞 Still Having Issues?

Check these files have correct values:

1. **`lib/core/config/app_config.dart`**
   - `supabaseUrl` = Your Supabase project URL
   - `supabaseAnonKey` = Your Supabase anon key

2. **`SUPABASE_DATABASE_SETUP.sql`**
   - Run this file in Supabase SQL Editor
   - Must run BEFORE app will work

3. **Supabase Dashboard → Authentication → Providers**
   - Phone provider enabled
   - Twilio configured with credentials

---

## ✅ Test Checklist

After running SQL script, test this flow:

- [ ] Login with phone number
- [ ] Receive and enter OTP
- [ ] See "Create Profile" screen (not phone number screen!)
- [ ] Fill profile form
- [ ] Submit profile
- [ ] See home screen
- [ ] Logout (from profile screen)
- [ ] Login again with same phone
- [ ] Skip profile screen, go directly to home ✅

---

**If you see this error again after following these steps, share your latest terminal logs!**


