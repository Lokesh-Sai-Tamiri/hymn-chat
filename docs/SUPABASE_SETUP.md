# 🚀 Supabase + Twilio Verify Setup Guide

Complete setup guide for phone authentication in HymnChat using Supabase and Twilio Verify.

---

## 📋 Prerequisites

- [ ] Flutter SDK installed
- [ ] Supabase account ([Sign up here](https://supabase.com))
- [ ] Twilio account with Verify service ([Sign up here](https://www.twilio.com))

---

## 🔧 Step 1: Configure Supabase Project

### 1.1 Create Supabase Project

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Click **"New Project"**
3. Enter:
   - **Project Name**: HymnChat (or any name)
   - **Database Password**: Create a strong password
   - **Region**: Select closest to your users
4. Click **"Create new project"**
5. Wait for setup to complete (~2 minutes)

### 1.2 Get Supabase Credentials

1. In Supabase Dashboard, go to **Settings → API**
2. Copy these values:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)

### 1.3 Enable Phone Authentication

1. In Supabase Dashboard, go to **Authentication → Providers**
2. Scroll down to **Phone**
3. Toggle **"Enable Phone provider"** to ON
4. **DO NOT** click save yet - we need Twilio credentials first

---

## 📱 Step 2: Configure Twilio Verify

### 2.1 Create Twilio Verify Service

1. Go to [Twilio Console](https://console.twilio.com)
2. Navigate to **Explore Products → Verify → Services**
3. Click **"Create new Verify Service"**
4. Enter:
   - **Friendly Name**: HymnChat OTP
   - **Use Case**: Select "User Verification"
5. Click **"Create"**

### 2.2 Get Twilio Credentials

You need three values from Twilio:

1. **Account SID**:
   - Go to [Twilio Console Dashboard](https://console.twilio.com)
   - Find under "Account Info"
   - Starts with `AC...`

2. **Auth Token**:
   - Same location as Account SID
   - Click the eye icon to reveal
   - Keep this secret!

3. **Verify Service SID**:
   - Go to **Verify → Services**
   - Click on your service
   - Copy the Service SID (starts with `VA...`)

---

## 🔗 Step 3: Connect Twilio to Supabase

1. Go back to Supabase Dashboard
2. Navigate to **Authentication → Providers → Phone**
3. Under **Phone provider settings**, select **Twilio Verify**
4. Enter your Twilio credentials:
   ```
   Account SID: AC_________________________
   Auth Token: ___________________________
   Message Service SID: VA_________________
   ```
5. Click **"Save"**
6. Test by clicking **"Send test SMS"**

---

## ⚙️ Step 4: Configure Flutter App

### 4.1 Update Config File

Open `lib/core/config/app_config.dart` and update:

```dart
class AppConfig {
  // Replace with your Supabase credentials
  static const String supabaseUrl = 'https://xxxxx.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGc...your-key-here';
  
  // Update these if needed
  static const String defaultCountryCode = '+91'; // Change for your region
  static const String defaultCountryFlag = '🇮🇳'; // Change flag emoji
}
```

### 4.2 Install Dependencies

```bash
cd /Users/lokeshst/Documents/Mobile\ App/HymnChat
flutter pub get
```

### 4.3 Run the App

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Web (testing only - SMS won't work on web)
flutter run -d chrome
```

---

## 🎯 Step 5: Test Authentication

### Test Flow:

1. **Open app** → Should show Login screen
2. **Enter phone number**: `+91 XXXXXXXXXX` (or your country)
3. **Click Continue** → OTP sent via Twilio
4. **Check your phone** → You'll receive SMS with 6-digit code
5. **Enter OTP** → Automatically verifies
6. **Success!** → Redirected to profile setup or home

### Debug Mode:

The app runs in debug mode by default. Check console for logs:

```
✅ Supabase initialized successfully
📱 Sending OTP to: +91XXXXXXXXXX
✅ OTP sent successfully via sms
🔐 Verifying OTP for: +91XXXXXXXXXX
✅ OTP verified successfully
```

---

## 💰 Cost Optimization Tips

### Current Setup Costs:
- **Supabase**: FREE (up to 50K monthly active users)
- **Twilio Verify**: ~$0.05 per verification

### Reduce Costs:

1. **Enable Rate Limiting** (already configured):
   - Max 5 OTP requests per day per number
   - 30-second cooldown between resends

2. **Use Email as Primary Auth** (optional):
   - Add email authentication
   - Use phone only for important actions
   - Reduces SMS costs by 60-70%

3. **WhatsApp OTP** (requires Twilio Business):
   - Cheaper: $0.005 vs $0.05
   - Change in config: `otpChannel = 'whatsapp'`

4. **Test Mode**:
   - Use Twilio test credentials during development
   - No charges for test SMS

---

## 🛠️ Troubleshooting

### Issue: "Invalid Supabase configuration"
**Solution**: Make sure you've updated `app_config.dart` with real credentials

### Issue: "OTP not received"
**Solutions**:
- Check Twilio account balance
- Verify phone number format includes country code
- Check Twilio logs in console
- Ensure phone number isn't blocked

### Issue: "Rate limit exceeded"
**Solution**: Wait or increase limits in `app_config.dart`:
```dart
static const int maxOtpRequestsPerDay = 10; // Increase if needed
```

### Issue: "Session expired"
**Solution**: Sessions last 1 hour by default. Configure in `app_config.dart`:
```dart
static const int sessionRefreshIntervalSeconds = 7200; // 2 hours
```

---

## 📊 Database Setup (Optional but Recommended)

Create a profiles table for user data:

1. Go to Supabase Dashboard → **SQL Editor**
2. Run this SQL:

```sql
-- Create profiles table
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  display_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Create function to auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, phone)
  VALUES (NEW.id, NEW.phone);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

## 🔐 Security Best Practices

1. **Never commit credentials**:
   - Add `.env` file support for production
   - Use environment variables
   - Keep `app_config.dart` in `.gitignore` if needed

2. **Enable RLS** (Row Level Security):
   - All tables should have RLS enabled
   - Users can only access their own data

3. **Rate Limiting**:
   - Keep enabled in production
   - Monitor abuse in Supabase Dashboard

4. **Session Management**:
   - Sessions auto-refresh
   - Force logout after inactivity (configure if needed)

---

## 📚 Additional Resources

- [Supabase Phone Auth Docs](https://supabase.com/docs/guides/auth/phone-login)
- [Twilio Verify Docs](https://www.twilio.com/docs/verify/api)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)

---

## 🎉 You're All Set!

Your HymnChat app now has:
- ✅ Phone number authentication
- ✅ SMS OTP via Twilio Verify
- ✅ Secure Supabase backend
- ✅ Rate limiting & error handling
- ✅ Auto session management
- ✅ Auth state guards

**Cost for first 10K users: ~$25-50/month** 💰

Need help? Check the troubleshooting section or reach out!

