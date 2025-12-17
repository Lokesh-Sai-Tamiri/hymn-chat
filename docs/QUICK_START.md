# ⚡ Quick Start Guide - HymnChat Phone Auth

## 🎯 What Was Implemented?

Your HymnChat app now has **complete phone authentication** using:
- ✅ **Supabase** (Backend & Auth)
- ✅ **Twilio Verify** (SMS OTP delivery)
- ✅ **Riverpod** (State management)
- ✅ **Auto session management**
- ✅ **Rate limiting & security**

---

## 📝 Configure in 3 Steps

### Step 1: Update Config File

Open: `lib/core/config/app_config.dart`

```dart
class AppConfig {
  // 👇 REPLACE THESE WITH YOUR CREDENTIALS
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
  
  // 👇 CUSTOMIZE FOR YOUR REGION (optional)
  static const String defaultCountryCode = '+91';  // Change if needed
  static const String defaultCountryFlag = '🇮🇳';   // Change flag
}
```

### Step 2: Get Your Credentials

**Supabase** (2 values):
1. Go to: https://app.supabase.com/project/_/settings/api
2. Copy: **Project URL** → Paste in `supabaseUrl`
3. Copy: **anon/public key** → Paste in `supabaseAnonKey`

**Twilio** (configure in Supabase Dashboard):
1. Get Twilio credentials:
   - Account SID (starts with `AC...`)
   - Auth Token
   - Verify Service SID (starts with `VA...`)
2. Go to: Supabase Dashboard → Authentication → Providers → Phone
3. Select: **Twilio Verify**
4. Paste credentials & Save

### Step 3: Run the App

```bash
flutter run
```

That's it! 🎉

---

## 🗂️ File Structure

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart          ⚙️ ALL CONFIG HERE
│   ├── services/
│   │   └── supabase_service.dart    🔧 Supabase initialization
│   └── router/
│       └── app_router.dart          🛣️ Routes + Auth guards
│
└── features/
    └── auth/
        ├── data/
        │   ├── models/
        │   │   └── auth_state_model.dart     📦 Auth & OTP state models
        │   └── repositories/
        │       └── auth_repository.dart      💾 Supabase auth calls
        └── presentation/
            ├── providers/
            │   └── auth_provider.dart        🎯 Riverpod providers
            └── screens/
                ├── login_screen.dart         📱 Phone input
                └── otp_screen.dart           🔐 OTP verification
```

---

## 🎨 Customization Options

All in `app_config.dart`:

### OTP Settings
```dart
static const int otpLength = 6;              // Code length
static const int otpExpirySeconds = 600;     // 10 minutes
static const int otpResendCooldownSeconds = 30;  // Resend delay
```

### Security
```dart
static const int maxOtpAttempts = 3;         // Before lockout
static const int maxOtpRequestsPerDay = 5;   // Rate limit
```

### Messages
```dart
static const Map<String, String> errorMessages = {
  'invalid_phone': 'Custom error message here',
  // ... edit any message
};
```

### Channel (SMS vs WhatsApp)
```dart
static const String otpChannel = 'sms';      // or 'whatsapp'
```

---

## 🧪 Testing

### Test with Real Phone Number:
1. Enter phone with country code: `+91 XXXXXXXXXX`
2. Receive SMS on your phone
3. Enter 6-digit code
4. ✅ Success!

### Debug Logs:
App prints helpful logs in debug mode:
```
✅ Supabase initialized successfully
📱 Sending OTP to: +91XXXXXXXXXX
✅ OTP sent successfully via sms
```

---

## 💰 Costs

### Free Tier (No Cost):
- First **50,000 users/month** on Supabase
- Twilio: **~$0.05 per SMS** (varies by country)

### Example:
- 1,000 users signup = **$50/month** in SMS costs
- 10,000 users = **$500/month**

### Reduce Costs:
- Use email auth as primary (FREE)
- Use phone only for verification
- Expected savings: **60-70%**

---

## 🔐 Security Features Included

✅ **Rate Limiting**: Max 5 OTP per day per number
✅ **Cooldown Timer**: 30s between resends
✅ **Session Auto-Refresh**: Keeps users logged in
✅ **Auth Guards**: Protected routes require login
✅ **Error Handling**: User-friendly messages
✅ **Input Validation**: Phone format checking

---

## 🐛 Common Issues

### "Invalid Supabase configuration"
➡️ Update credentials in `app_config.dart`

### "OTP not received"
➡️ Check:
- Twilio account has balance
- Phone number format correct
- Country code included

### "Rate limit exceeded"
➡️ Increase limit in config or wait 24 hours

---

## 📚 Need More Help?

See **SUPABASE_SETUP.md** for:
- Detailed setup instructions
- Database schema
- Troubleshooting guide
- Advanced configuration

---

## 🎉 What's Next?

Your authentication is ready! Now you can:

1. **Test it**: Run app and try login
2. **Customize UI**: Update colors/styles in screens
3. **Add features**: Profile setup, user data, etc.
4. **Deploy**: Build and release!

---

**Made with ❤️ for cost-effective phone auth**

Questions? Check console logs or see SUPABASE_SETUP.md

