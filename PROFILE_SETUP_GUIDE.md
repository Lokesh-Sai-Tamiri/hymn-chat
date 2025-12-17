# 📋 Profile Setup - Complete Guide

## ✅ What's Implemented

Complete profile system with Snapchat-style onboarding:
- ✅ Database schema with profiles table
- ✅ Comprehensive profile form (first name, last name, email, doctor ID, address, etc.)
- ✅ Profile completion check after phone verification
- ✅ Auto-routing based on profile status
- ✅ All profile data saved to Supabase

---

## 🗄️ Step 1: Create Database Table

**Run this SQL in Supabase Dashboard:**

1. Go to: **Supabase Dashboard → SQL Editor**
2. Click **"New Query"**
3. Copy & paste contents from: `SUPABASE_DATABASE_SETUP.sql`
4. Click **"Run"**

This creates:
- ✅ `profiles` table with all fields
- ✅ Row Level Security policies
- ✅ Indexes for performance
- ✅ Auto-create profile on user signup trigger

---

## 📱 Step 2: How It Works

### User Flow:

```
1. User enters phone number
   ↓
2. Receives & enters OTP
   ↓
3. App checks: Has user completed profile?
   ↓
   NO → Show Profile Form
   YES → Go to Home
   ↓
4. User fills profile form:
   - First Name (required)
   - Last Name (required)
   - Email (required)
   - Doctor ID (optional)
   - Specialization (optional)
   - Clinic Name (optional)
   - Address (optional)
   ↓
5. Profile saved to Supabase
   ↓
6. Navigate to Home
```

---

## 📊 Profile Fields

### Required Fields:
- ✅ First Name
- ✅ Last Name
- ✅ Email

### Optional Fields (Professional):
- Doctor/Medical ID
- Specialization
- Clinic/Hospital Name
- Years of Experience

### Optional Fields (Address):
- Address Line 1
- Address Line 2
- City
- State
- Postal Code
- Country (default: India)

### Auto-filled:
- Phone (from auth)
- User ID (from auth)

---

## 🛠️ Files Created/Updated

### New Files:
```
lib/features/profile/data/models/profile_model.dart
lib/features/profile/data/repositories/profile_repository.dart
lib/features/profile/presentation/providers/profile_provider.dart
SUPABASE_DATABASE_SETUP.sql
```

### Updated Files:
```
lib/features/auth/presentation/screens/otp_screen.dart       (Fixed navigation crash)
lib/features/auth/data/repositories/auth_repository.dart     (Profile check logic)
lib/features/profile/presentation/screens/create_profile_screen.dart  (Complete form)
```

---

## 🎨 UI Features

### Profile Form Includes:
- ✅ Section headers (Basic Info, Professional, Address)
- ✅ Clean, modern input fields
- ✅ Icons for each field
- ✅ Validation for required fields
- ✅ Smooth animations
- ✅ Loading state while saving
- ✅ Success/error messages

### Like Snapchat:
- ✅ Can't skip profile creation (required after login)
- ✅ Clear section organization
- ✅ Optional vs. required fields clearly marked
- ✅ Smooth transitions

---

## 🔧 Configuration

In `app_config.dart`:

```dart
/// Profile fields required
static const List<String> requiredProfileFields = [
  'first_name',
  'last_name',
  'email',
];
```

---

## 🐛 Bug Fixes Included

### Fixed Issues:
1. ✅ **Token expiration** - Auto-refresh implemented
2. ✅ **Navigation crash** - Used `SchedulerBinding.addPostFrameCallback`
3. ✅ **TextEditingController disposed error** - Fixed lifecycle
4. ✅ **Database table missing** - SQL script provided

---

## 🧪 Testing

### Test Profile Creation:

1. **Clear existing data** (optional):
   ```sql
   -- In Supabase SQL Editor
   DELETE FROM public.profiles WHERE phone = '+917993598294';
   DELETE FROM auth.users WHERE phone = '917993598294';
   ```

2. **Run app**:
   ```bash
   flutter run
   ```

3. **Test flow**:
   - Enter phone number
   - Enter OTP
   - Should show profile form (if no profile exists)
   - Fill required fields
   - Click "Complete Profile"
   - Should navigate to home

4. **Test existing profile**:
   - Close app
   - Re-login with same number
   - Should skip profile form → Go directly to home ✅

---

## 📊 Database Structure

```sql
profiles table:
- id (UUID, Primary Key)
- first_name (TEXT)
- last_name (TEXT)
- display_name (TEXT)
- email (TEXT)
- phone (TEXT)
- doctor_id (TEXT, Unique)
- specialization (TEXT)
- clinic_name (TEXT)
- years_of_experience (INTEGER)
- address_line1 (TEXT)
- address_line2 (TEXT)
- city (TEXT)
- state (TEXT)
- postal_code (TEXT)
- country (TEXT, default: 'India')
- avatar_url (TEXT)
- bio (TEXT)
- profile_completed (BOOLEAN, default: FALSE)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

---

## 🔐 Security

### Row Level Security (RLS):
- ✅ Users can only read their own profile
- ✅ Users can only create their own profile
- ✅ Users can only update their own profile
- ✅ No user can delete profiles

### Auto-creation:
- ✅ Profile auto-created on user signup (with phone only)
- ✅ User completes profile on first login
- ✅ `profile_completed` flag prevents re-showing form

---

## 📱 Example Profile Data

```json
{
  "id": "4e7fa4d2-a293-48ff-85e0-2215314dc500",
  "first_name": "Lokesh",
  "last_name": "ST",
  "display_name": "Lokesh ST",
  "email": "lokesh@example.com",
  "phone": "+917993598294",
  "doctor_id": "DOC12345",
  "specialization": "Cardiologist",
  "clinic_name": "City Hospital",
  "address_line1": "123 Main Street",
  "city": "Bangalore",
  "state": "Karnataka",
  "postal_code": "560001",
  "country": "India",
  "profile_completed": true
}
```

---

## 🎯 Next Steps

After profile is set up, you can:

1. **Add profile editing**: Let users update their profile
2. **Add avatar upload**: Profile photo functionality
3. **Add bio/about**: Personal description
4. **Add verification**: Verify doctor IDs
5. **Add profile viewing**: See other users' profiles

---

## 💡 Tips

### For Testing:
- Use different phone numbers to test fresh profile creation
- Check Supabase dashboard to see saved profiles
- Enable `debugMode = true` to see detailed logs

### For Production:
- Add email verification
- Add document upload for doctor verification
- Add profile visibility settings
- Add profile completion percentage

---

## 🎉 Summary

You now have:
- ✅ Complete phone authentication
- ✅ Automatic token refresh
- ✅ Comprehensive profile system
- ✅ Snapchat-style onboarding
- ✅ Database with RLS
- ✅ Profile completion check
- ✅ Smart routing based on profile status

**Users will:**
1. Login with phone
2. Fill profile once
3. Skip profile form on subsequent logins
4. Go directly to home ✅

---

**Setup time: ~5 minutes** (just run the SQL script!)

**User experience: Professional & smooth!** 🚀

