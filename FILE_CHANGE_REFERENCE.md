# File Change Reference - Exact Locations

## Quick Location Guide for All Changes

---

## File 1: avaliable_options_widget.dart

### Import Addition

**Location:** Line 11 (with other imports)

```
ADDED: import 'package:razorpay_flutter/razorpay_flutter.dart';
```

### State Variables Addition

**Location:** Lines 57-60 (within `_AvaliableOptionsWidgetState` class)

```dart
// Razorpay & Wallet
late Razorpay _razorpay;
double? _walletBalance;
int? _rideAmountForPayment;
```

### initState() Enhancement

**Location:** Lines 63-78 (after super.initState() and \_model setup)

```dart
// Initialize Razorpay
_razorpay = Razorpay();
_razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
_razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
```

### dispose() Addition

**Location:** Lines 89-94 (new method after initState)

```dart
@override
void dispose() {
  _razorpay.clear();
  _slideController.dispose();
  super.dispose();
}
```

### \_confirmBooking() Update

**Location:** Lines 285-365 (existing method, UPDATED)

**Key Changes:**

- Line 312-317: Added wallet payment check
- Line 319: Added wallet check condition
- Line 322-325: Return early if payment failed
- Line 332-338: Updated CreateRideCall (unchanged parameter positions)

### New Methods Addition

**Location:** Lines 366-510 (4 new methods before \_buildUI comment)

1. **\_handleWalletPayment()** - Lines 366-425
2. **\_openRazorpayForWallet()** - Lines 427-445
3. **\_handlePaymentSuccess()** - Lines 447-492
4. **\_handlePaymentError()** - Lines 494-501

---

## File 2: auto_book_widget.dart

### \_handleCompletedRideNavigation() Update

**Location:** Lines 365-403 (existing method, UPDATED)

**Key Addition:**
Lines 385-403: Added wallet balance refresh logic

**BEFORE (Lines 365-385):**

```dart
Future<void> _handleCompletedRideNavigation(Map<String, dynamic> rideData) async {
  _stopDistanceUpdateTimer();
  socket?.off("ride_updated");

  RideSession().rideData = rideData;

  // Ensure we have driver data before navigating
  if (driverDetails != null) {
    RideSession().driverData = driverDetails;
  } else if (rideData['driver'] != null) {
    final nestedDriver = rideData['driver'];
    RideSession().driverData = nestedDriver is Map<String, dynamic>
        ? nestedDriver
        : Map<String, dynamic>.from(nestedDriver);
  } else if (rideData['driver_id'] != null) {
    await _fetchDriverDetailsSync(rideData['driver_id']);
  }

  if (mounted) {
    context.goNamed(RidecompleteWidget.routeName);
  }
}
```

**AFTER (Lines 365-403):**

```dart
Future<void> _handleCompletedRideNavigation(Map<String, dynamic> rideData) async {
  _stopDistanceUpdateTimer();
  socket?.off("ride_updated");

  RideSession().rideData = rideData;

  // Ensure we have driver data before navigating
  if (driverDetails != null) {
    RideSession().driverData = driverDetails;
  } else if (rideData['driver'] != null) {
    final nestedDriver = rideData['driver'];
    RideSession().driverData = nestedDriver is Map<String, dynamic>
        ? nestedDriver
        : Map<String, dynamic>.from(nestedDriver);
  } else if (rideData['driver_id'] != null) {
    await _fetchDriverDetailsSync(rideData['driver_id']);
  }

  // ✅ REFRESH WALLET BALANCE IF WALLET PAYMENT WAS USED
  final paymentMethod = rideData['payment_method'] ?? rideData['payment_type'];
  if (paymentMethod != null && paymentMethod.toString().toLowerCase() == 'wallet') {
    print('💳 Ride completed with Wallet payment, refreshing wallet balance...');
    try {
      final appState = FFAppState();
      final walletRes = await GetwalletCall.call(
        userId: appState.userid,
        token: appState.accessToken,
      );

      if (walletRes.succeeded) {
        final balanceStr = GetwalletCall.walletBalance(walletRes.jsonBody);
        final double balance = double.tryParse(balanceStr ?? '0') ?? 0.0;
        appState.walletBalance = balance;
        print('✅ Wallet balance refreshed: ₹${balance.toStringAsFixed(2)}');
      }
    } catch (e) {
      print('⚠️ Error refreshing wallet: $e');
      // Don't fail the navigation if wallet refresh fails
    }
  }

  if (mounted) {
    context.goNamed(RidecompleteWidget.routeName);
  }
}
```

---

## Summary of Changes

### avaliable_options_widget.dart

| Element                   | Line(s) | Type    |
| ------------------------- | ------- | ------- |
| Razorpay Import           | 11      | NEW     |
| State Variables           | 57-60   | NEW     |
| dispose() method          | 89-94   | NEW     |
| initState() update        | 63-78   | UPDATED |
| \_confirmBooking()        | 312-325 | UPDATED |
| \_handleWalletPayment()   | 366-425 | NEW     |
| \_openRazorpayForWallet() | 427-445 | NEW     |
| \_handlePaymentSuccess()  | 447-492 | NEW     |
| \_handlePaymentError()    | 494-501 | NEW     |

**Total Lines Added:** ~280  
**Total Lines Modified:** ~50

### auto_book_widget.dart

| Element                           | Line(s) | Type    |
| --------------------------------- | ------- | ------- |
| \_handleCompletedRideNavigation() | 385-403 | UPDATED |

**Total Lines Added:** ~20

---

## Files NOT Changed (Reference Only)

These files are used but NOT modified:

- `lib/backend/api_requests/api_calls.dart` - Contains API definitions
- `lib/wallet/wallet_widget.dart` - Wallet UI screen
- `lib/index.dart` - Index/exports file

---

## Testing Locations

### Test Points in avaliable_options_widget.dart

1. **Payment Method Selection**
   - Location: `_buildBottomActions()` method (~line 690)
   - What to test: User can select "Wallet"

2. **Booking Flow**
   - Location: `_confirmBooking()` method (line 288)
   - What to test: Click "Confirm Booking" with wallet selected

3. **Balance Check**
   - Location: `_handleWalletPayment()` method (line 395)
   - What to test: Balance is fetched correctly

4. **Razorpay Opening**
   - Location: `_openRazorpayForWallet()` method (line 427)
   - What to test: Dialog opens with correct amount

5. **Payment Success**
   - Location: `_handlePaymentSuccess()` method (line 447)
   - What to test: Wallet updated after payment

### Test Points in auto_book_widget.dart

1. **Ride Completion**
   - Location: `_handleCompletedRideNavigation()` method (line 385)
   - What to test: Wallet refreshed after completion

---

## Debug Log Locations

All debug logs use the following format with emojis for easy filtering:

```
💳 - Wallet-related messages
🚗 - Ride-related messages
💰 - Balance-related messages
✅ - Success messages
❌ - Error messages
⚠️ - Warning messages
```

**Locations:**

- `_handleWalletPayment()` - Lines 370-385 (multiple logs)
- `_openRazorpayForWallet()` - Line 437 (error)
- `_handlePaymentSuccess()` - Lines 450, 457, 465, 471, 478, 481 (multiple logs)
- `_handlePaymentError()` - Line 498 (error)
- `_handleCompletedRideNavigation()` - Lines 387, 392, 399 (multiple logs)

---

## Diff Summary

### Quick Diff View

```diff
=== avaliable_options_widget.dart ===
+ import 'package:razorpay_flutter/razorpay_flutter.dart';

class _AvaliableOptionsWidgetState extends State<AvaliableOptionsWidget> {
+ late Razorpay _razorpay;
+ double? _walletBalance;
+ int? _rideAmountForPayment;

  @override
  void initState() {
+   _razorpay = Razorpay();
+   _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
+   _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

+ @override
+ void dispose() {
+   _razorpay.clear();
+   _slideController.dispose();
+   super.dispose();
+ }

  Future<void> _confirmBooking() async {
+   if (selectedPaymentMethod == 'Wallet') {
+     final walletCheckResult = await _handleWalletPayment(appState, finalFare);
+     if (!walletCheckResult) {
+       return;
+     }
+   }
    // ... rest of method ...
  }

+ Future<bool> _handleWalletPayment(...) { ... }
+ void _openRazorpayForWallet(...) { ... }
+ void _handlePaymentSuccess(...) { ... }
+ void _handlePaymentError(...) { ... }
}

=== auto_book_widget.dart ===
  Future<void> _handleCompletedRideNavigation(Map<String, dynamic> rideData) async {
    // ... existing code ...

+   // ✅ REFRESH WALLET BALANCE IF WALLET PAYMENT WAS USED
+   final paymentMethod = rideData['payment_method'] ?? rideData['payment_type'];
+   if (paymentMethod != null && paymentMethod.toString().toLowerCase() == 'wallet') {
+     print('💳 Ride completed with Wallet payment, refreshing wallet balance...');
+     try {
+       final appState = FFAppState();
+       final walletRes = await GetwalletCall.call(...);
+       if (walletRes.succeeded) {
+         final balanceStr = GetwalletCall.walletBalance(walletRes.jsonBody);
+         final double balance = double.tryParse(balanceStr ?? '0') ?? 0.0;
+         appState.walletBalance = balance;
+         print('✅ Wallet balance refreshed: ₹${balance.toStringAsFixed(2)}');
+       }
+     } catch (e) {
+       print('⚠️ Error refreshing wallet: $e');
+     }
+   }
  }
```

---

## How to Verify Implementation

### Check 1: All Imports Present

```bash
# Should show the Razorpay import
grep -n "razorpay_flutter" lib/avaliable_options/avaliable_options_widget.dart
```

### Check 2: All Methods Present

```bash
# Should show 4 new methods
grep -n "def _handleWallet\|def _openRazorpay\|def _handlePayment" lib/avaliable_options/avaliable_options_widget.dart
```

### Check 3: auto_book_widget Updated

```bash
# Should show wallet payment check
grep -n "wallet" lib/auto_book/auto_book_widget.dart
```

### Check 4: No Syntax Errors

```bash
# Compile check
flutter analyze
```

---

## Rollback Instructions (if needed)

### To Rollback avaliable_options_widget.dart

1. Remove line 11 (Razorpay import)
2. Remove lines 57-60 (state variables)
3. Remove lines 89-94 (dispose method)
4. Remove lines 63-78 (initState Razorpay setup)
5. Revert lines 312-325 in \_confirmBooking()
6. Remove methods at lines 366-510

### To Rollback auto_book_widget.dart

1. Remove lines 385-403 (wallet refresh code)

---

## File Size Impact

| File                          | Before          | After           | Change         |
| ----------------------------- | --------------- | --------------- | -------------- |
| avaliable_options_widget.dart | 636 lines       | 916 lines       | +280 lines     |
| auto_book_widget.dart         | 580 lines       | 600 lines       | +20 lines      |
| **Total**                     | **1,216 lines** | **1,516 lines** | **+300 lines** |

---

**Reference Complete! 📍**

Use this file to quickly locate any part of the implementation.
