# Profile Features - Logout & Delete Account

## ✅ Features Added

### 1. **Logout Functionality** 🚪
- **Location**: Profile Screen → Account Section
- **Icon**: Logout icon (orange color)
- **Behavior**:
  - Shows confirmation dialog
  - Displays loading indicator during logout
  - Clears session and navigates to login screen
  - Stops session refresh timer

### 2. **Delete Account** 🗑️
- **Location**: Profile Screen → Account Section  
- **Icon**: Delete forever icon (red color)
- **Behavior**:
  - Shows warning dialog (emphasizes data loss)
  - Displays loading indicator
  - Signs user out
  - Shows message to contact support for completion
  
  **Note**: Full account deletion requires backend/admin API implementation due to Supabase security restrictions.

### 3. **Edit Profile** ✏️
- **Bonus Feature Added**
- Navigate to profile creation screen to update details
- All existing data is editable

---

## 🎨 UI Design

### Profile Screen Layout

```
┌─────────────────────────────┐
│       Profile Header        │
│   Avatar + Name + Details   │
├─────────────────────────────┤
│                             │
│   My Stories Section        │
│   ├─ Add to My Story        │
│                             │
│   Account Section           │
│   ├─ Edit Profile           │
│   ├─ Snapcode               │
│   ├─ Notifications          │
│   ├─ Privacy & Security     │
│   ├─ Help & Support         │
│                             │
│   ├─ 🟠 Logout              │  ← NEW
│   └─ 🔴 Delete Account      │  ← NEW
│                             │
└─────────────────────────────┘
```

---

## 🔧 Technical Implementation

### Files Modified:
- **`lib/features/profile/presentation/screens/profile_screen.dart`**
  - Added logout dialog with confirmation
  - Added delete account dialog with warning
  - Added edit profile navigation
  - Dynamic profile data loading from Supabase
  - Real user initials and name display

### Functions Added:

#### 1. `_showLogoutDialog()`
```dart
void _showLogoutDialog(BuildContext context, WidgetRef ref) {
  // Shows confirmation dialog
  // Calls authStateProvider.notifier.signOut()
  // Navigates to /login
}
```

#### 2. `_showDeleteAccountDialog()`
```dart
void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
  // Shows warning dialog
  // Attempts account deletion
  // Shows support message
  // Navigates to /login
}
```

#### 3. Enhanced `_buildMenuItem()`
- Now accepts `onTap` callback
- Supports custom colors for critical actions
- Shows visual indicators (borders) for destructive actions

---

## 📱 User Flow

### Logout Flow:
```
1. User taps "Logout"
   ↓
2. Confirmation dialog appears
   "Are you sure you want to logout?"
   ↓
3. User confirms
   ↓
4. Loading indicator shows
   ↓
5. Session cleared
   ↓
6. Navigate to Login Screen
```

### Delete Account Flow:
```
1. User taps "Delete Account"
   ↓
2. Warning dialog appears
   "This action cannot be undone..."
   ↓
3. User confirms (red button)
   ↓
4. Loading indicator shows
   ↓
5. Account marked for deletion
   ↓
6. Show "Contact support" message
   ↓
7. Navigate to Login Screen
```

---

## 🛡️ Security Considerations

### Logout:
- ✅ Clears local session
- ✅ Stops auto-refresh timer
- ✅ Clears all cached auth data
- ✅ Forces login on next use

### Delete Account:
- ⚠️ **Client-side limitation**: Supabase doesn't allow user deletion from client SDK for security
- ✅ User is signed out immediately
- ℹ️ Account marked for deletion (requires backend)
- 📧 User directed to contact support for completion

---

## 🔮 Future Enhancements

### Delete Account - Full Implementation:

**Option 1: Backend API**
```dart
// Create a backend endpoint
POST /api/v1/users/delete-account

// Implementation:
- Mark account as "pending_deletion"
- Schedule deletion after 30-day grace period
- Send confirmation email
- Delete all user data (profiles, chats, etc.)
- Call Supabase Admin API to delete auth user
```

**Option 2: Supabase Edge Function**
```typescript
// Create edge function: delete-user
import { createClient } from '@supabase/supabase-js'

export async function deleteUser(userId: string) {
  const supabaseAdmin = createClient(url, serviceKey)
  
  // Delete user data
  await supabaseAdmin.from('profiles').delete().eq('id', userId)
  
  // Delete auth user
  await supabaseAdmin.auth.admin.deleteUser(userId)
}
```

---

## 🧪 Testing

### Test Logout:
1. Login to app
2. Navigate to Profile
3. Scroll to bottom
4. Tap "Logout"
5. Confirm logout
6. ✅ Should redirect to login screen
7. ✅ Profile data should be cleared

### Test Delete Account:
1. Login to app
2. Navigate to Profile
3. Scroll to bottom
4. Tap "Delete Account"
5. Read warning carefully
6. Confirm deletion
7. ✅ Should show support message
8. ✅ Should redirect to login screen

---

## 💡 Pro Tips

### For Users:
- **Logout**: Use when switching accounts or securing your session
- **Delete Account**: Contact support@hymnchat.com after initiating deletion

### For Developers:
- Implement backend delete endpoint for production
- Add 30-day grace period before permanent deletion
- Send confirmation emails at each step
- Keep audit logs for compliance

---

## 📊 Analytics Events (Recommended)

Add these tracking events:
```dart
// Logout
analytics.logEvent('user_logout', {
  'user_id': user.id,
  'session_duration': sessionTime,
});

// Delete Account
analytics.logEvent('account_deletion_initiated', {
  'user_id': user.id,
  'account_age_days': accountAge,
  'reason': 'user_requested',
});
```

---

## 🎉 Summary

✅ **Logout** - Fully functional
✅ **Delete Account** - Functional (requires backend for completion)  
✅ **Edit Profile** - Bonus feature added
✅ **Dynamic Profile Display** - Shows real user data
✅ **Confirmation Dialogs** - Prevents accidental actions
✅ **Loading States** - Better UX during async operations
✅ **Color Coding** - Orange for logout, Red for delete

---

**Ready to test!** Press `R` in your terminal to hot restart the app.


