# Firebase Setup Guide for PillCare

## Issue: "Error" on Sign Up

This usually means **Firestore security rules are not configured**. Follow these steps:

### Step 1: Set Up Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project **pillcare**
3. Go to **Build → Firestore Database**
4. Click **Create Database**
5. Choose **Start in test mode** (for development)
6. Select location: **us-central1** (or closest to you)
7. Click **Create**

### Step 2: Update Firestore Security Rules

1. In Firestore, go to **Rules** tab
2. Replace the existing rules with:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Allow authenticated users to read/write medications
    match /medications/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write alerts
    match /alerts/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write chat
    match /chat/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

3. Click **Publish**

### Step 3: Test

1. Restart your Flutter app
2. Try creating a new account again
3. Check [Firestore Console](https://console.firebase.google.com/) → Firestore → **Data** tab to verify the user document was created

## Common Errors & Solutions

| Error | Solution |
|-------|----------|
| Network error | Check internet connection |
| Email already in use | Use a different email |
| Permission denied | Check Firestore rules (Step 2 above) |
| Firebase not initialized | Restart the app |

## Testing Tips

- Use test emails like `test1@example.com`, `test2@example.com`
- Use `password123` for consistency during testing
- Check browser console (F12) for detailed errors

## For Production

When ready for production:
1. Change Firestore rules from "test mode" to more restrictive rules
2. Enable Email Verification
3. Set up proper authentication providers
4. Configure CORS if needed for web
