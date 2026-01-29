# Guest User Restrictions Implementation

## Overview
Guest users are now restricted from performing certain actions in the app:
- **Cannot save visits** on the Add Visit page
- **Cannot proceed with booking or holding plots** on the Select Project & Plot page

When guests attempt these actions, they see an alert dialog prompting them to sign in.

## Implementation Details

### 1. Guest Alert Helper
**File:** `lib/module/widgets/guest_alert_helper.dart`

A reusable helper class that shows a consistent alert dialog for guest users:
- Displays an info icon with "Guest User" title
- Shows a custom message explaining the restriction
- Provides two actions:
  - **Cancel**: Closes the dialog
  - **Sign In**: Navigates to the sign-in screen

### 2. Add Visit Restriction
**File:** `lib/module/widgets/add_visit_dialog.dart`

#### Changes needed:
1. Add import:
```dart
import 'guest_alert_helper.dart';
```

2. In the `_saveVisit()` method, replace `_showGuestUserAlert();` with:
```dart
GuestAlertHelper.showGuestAlert(
  context,
  message: 'Guest users cannot save visits. Please sign in with your phone number to access all features.',
);
```

The guest check is already implemented at line 1293-1301. You just need to update the alert call.

### 3. Select Project & Plot Restriction  
**File:** `lib/module/widgets/booking/booking_form_section.dart` ✅ **COMPLETED**

Added guest user check in the `_handleNext()` method:
- Checks if user is a guest before proceeding
- Shows alert if guest attempts to continue
- Only calls the `onNext` callback if user is not a guest

## User Experience Flow

### When Guest User Tries to Save Visit:
1. User fills out the Add Visit form
2. User clicks "Save Visit" button
3. App checks if user is a guest
4. If guest, shows alert dialog:
   - **Title**: "Guest User"
   - **Message**: "Guest users cannot save visits..."
   - **Actions**: Cancel | Sign In
5. If user clicks "Sign In", navigates to sign-in screen
6. If user clicks "Cancel", closes dialog and stays on form

### When Guest User Tries to Book/Hold Plot:
1. User selects a project and plot
2. User clicks "Next" button
3. App checks if user is a guest
4. If guest, shows alert dialog:
   - **Title**: "Guest User"
   - **Message**: "Guest users cannot book or hold plots..."
   - **Actions**: Cancel | Sign In
5. Same navigation behavior as above

## Technical Details

### Guest User Detection
```dart
final isGuest = await _secureStorage.read(key: SharedPreferenceStrings.isGuest);
if (isGuest == 'true') {
  // Show alert
  GuestAlertHelper.showGuestAlert(context, message: '...');
  return;
}
```

### Alert Dialog Features
- Rounded corners (16px border radius)
- Primary color icon and Sign In button
- Secondary color text for Cancel button
- Responsive layout
- Prevents action if user cancels

## Testing

### Test Cases:

**1. Guest User Restrictions:**
- ✅ Guest cannot save visits
- ✅ Guest cannot proceed to customer selection in booking
- ✅ Guest cannot proceed to customer selection in hold
- ✅ Alert shows correct message
- ✅ "Sign In" button navigates to login screen
- ✅ "Cancel" button closes dialog

**2. Regular User Flow:**
- ✅ Regular users can save visits normally
- ✅ Regular users can proceed with booking/hold
- ✅ No alert shown for authenticated users

## Files Modified

1. ✅ **Created**: `lib/module/widgets/guest_alert_helper.dart`
2. ⚠️ **Needs Update**: `lib/module/widgets/add_visit_dialog.dart` (add import and update alert call)
3. ✅ **Updated**: `lib/module/widgets/booking/booking_form_section.dart`

## Additional Restrictions (Future)

Consider adding guest restrictions to:
- Customer creation/editing
- Document uploads
- Profile editing
- Any other create/update operations

Use the same pattern:
```dart
final isGuest = await _secureStorage.read(key: SharedPreferenceStrings.isGuest);
if (isGuest == 'true') {
  GuestAlertHelper.showGuestAlert(
    context,
    message: 'Your custom message here',
  );
  return;
}
```

## Notes

- Guest users can still browse projects, plots, and visit history
- Guest users can view all content but cannot modify data
- The `isGuest` flag is stored in secure storage and cleared on logout
- Guest users are identified by phone number `+919998880060` on the backend
