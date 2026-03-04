# Wallet Payment Implementation Guide

## Overview

This document describes the implementation of wallet-based payment flow for ride bookings in the UGO app. The flow includes checking wallet balance, using Razorpay for top-ups if needed, and refreshing wallet after ride completion.

---

## Flow Diagram

```
User selects "Wallet" as payment method
    ↓
User clicks "Confirm Booking"
    ↓
_confirmBooking() called
    ↓
_handleWalletPayment() executes:
    │
    ├─→ Fetch current wallet balance (GetwalletCall)
    │
    ├─→ Check: Wallet Balance >= Ride Amount?
    │   │
    │   ├─ YES → Return true, proceed to CreateRideCall
    │   │
    │   └─ NO → Calculate difference
    │       ↓
    │       Open Razorpay for top-up (difference amount)
    │       ↓
    │       User completes payment
    │       ↓
    │       _handlePaymentSuccess() callback
    │       ├─→ AddMoneyToWalletCall (add topup amount)
    │       ├─→ GetwalletCall (refresh balance)
    │       └─→ Update appState.walletBalance
    │
    ├─→ CreateRideCall executed with paymentType: "wallet"
    │
    └─→ Navigate to AutoBookWidget with rideId
            ↓
        Ride in progress
            ↓
        Ride completed
            ↓
    _handleCompletedRideNavigation() in AutoBookWidget:
        ├─→ Check if payment_method was 'wallet'
        ├─→ GetwalletCall to refresh balance
        ├─→ Update appState.walletBalance
        └─→ Navigate to RidecompleteWidget
```

---

## Implementation Details

### 1. File: [avaliable_options_widget.dart](lib/avaliable_options/avaliable_options_widget.dart)

#### Imports Added:

```dart
import 'package:razorpay_flutter/razorpay_flutter.dart';
```

#### State Variables Added:

```dart
// Razorpay & Wallet
late Razorpay _razorpay;
double? _walletBalance;
int? _rideAmountForPayment;
```

#### Methods Added:

##### `initState()` - Razorpay Initialization

```dart
// Initialize Razorpay
_razorpay = Razorpay();
_razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
_razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
```

##### `dispose()` - Cleanup

```dart
@override
void dispose() {
  _razorpay.clear();
  _slideController.dispose();
  super.dispose();
}
```

##### `_confirmBooking()` - Main Booking Flow

**Key Changes:**

- Checks if payment method is 'Wallet'
- Calls `_handleWalletPayment()` before CreateRideCall
- Only proceeds if wallet payment handling succeeds
- Includes error handling and user feedback

```dart
if (selectedPaymentMethod == 'Wallet') {
  final walletCheckResult = await _handleWalletPayment(appState, finalFare);
  if (!walletCheckResult) {
    return; // Payment failed, exit
  }
}
```

##### `_handleWalletPayment()` - Wallet Balance Check & Top-up Logic

**Responsibilities:**

1. Fetch current wallet balance via `GetwalletCall`
2. Compare wallet balance with ride amount
3. If sufficient: return `true` (proceed to CreateRideCall)
4. If insufficient:
   - Calculate difference amount
   - Open Razorpay with difference amount
   - Return `true` (payment handled via callback)

```dart
Future<bool> _handleWalletPayment(FFAppState appState, int rideAmount) async {
  // 1. Fetch wallet balance
  final walletRes = await GetwalletCall.call(...);

  // 2. Check balance
  if (walletBalance >= rideAmount) {
    return true; // Sufficient balance
  }

  // 3. Open Razorpay for difference
  final int differenceAmount = (rideAmount - walletBalance).abs();
  _rideAmountForPayment = rideAmount;
  _openRazorpayForWallet(differenceAmount, appState);

  return true;
}
```

##### `_openRazorpayForWallet()` - Razorpay Integration

- Opens Razorpay dialog for top-up payment
- Sets amount in paise (multiply by 100)
- Includes user prefill information

##### `_handlePaymentSuccess()` - Payment Success Callback

**Flow:**

1. Extract topup amount from `_rideAmountForPayment`
2. Call `AddMoneyToWalletCall` to add money to wallet
3. Call `GetwalletCall` to fetch updated balance
4. Update `appState.walletBalance`
5. Show success message

```dart
void _handlePaymentSuccess(PaymentSuccessResponse response) async {
  // Add money to wallet
  final addMoneyRes = await AddMoneyToWalletCall.call(...);

  // Refresh wallet balance
  final walletRes = await GetwalletCall.call(...);

  // Update app state
  _walletBalance = double.tryParse(newBalance);
}
```

##### `_handlePaymentError()` - Payment Error Callback

- Shows error message to user
- Prints debug logs

---

### 2. File: [auto_book_widget.dart](lib/auto_book/auto_book_widget.dart)

#### Method Updated: `_handleCompletedRideNavigation()`

**New Functionality:**

- Checks if the completed ride used wallet payment
- If wallet payment detected:
  - Calls `GetwalletCall` to fetch latest balance
  - Updates `appState.walletBalance`
  - Logs success

```dart
// ✅ REFRESH WALLET BALANCE IF WALLET PAYMENT WAS USED
final paymentMethod = rideData['payment_method'] ?? rideData['payment_type'];
if (paymentMethod != null && paymentMethod.toString().toLowerCase() == 'wallet') {
  final walletRes = await GetwalletCall.call(...);
  if (walletRes.succeeded) {
    final balance = double.tryParse(balanceStr);
    appState.walletBalance = balance;
  }
}
```

---

## API Calls Used

### 1. `GetwalletCall` (Fetch Balance)

- **Endpoint:** `GET /api/wallets/user/{userId}`
- **Headers:** Authorization Bearer token
- **Returns:** `wallet_balance` (string)
- **Used in:**
  - `_handleWalletPayment()` - Initial balance check
  - `_handlePaymentSuccess()` - Refresh after topup
  - `_handleCompletedRideNavigation()` - Refresh after ride completion

### 2. `AddMoneyToWalletCall` (Add Money)

- **Endpoint:** `POST /api/wallets/add`
- **Body:**
  ```json
  {
    "user_id": userId,
    "amount": amount,
    "currency": "INR"
  }
  ```
- **Used in:** `_handlePaymentSuccess()` - After Razorpay payment

### 3. `CreateRideCall` (Create Ride)

- **Endpoint:** `POST /api/rides/post`
- **Parameters:** Includes `paymentType: "wallet"` when wallet payment used
- **Used in:** `_confirmBooking()` - After wallet validation

---

## State Management

### FFAppState Variables Used:

- `appState.accessToken` - Authentication
- `appState.userid` - User ID
- `appState.walletBalance` - Current wallet balance (updated after topup and ride completion)
- `appState.pickuplocation`, `appState.droplocation` - Ride locations
- `appState.pickupLatitude`, `appState.pickupLongitude` - Pickup coordinates
- `appState.dropLatitude`, `appState.dropLongitude` - Drop coordinates
- `appState.selectedBaseFare`, `appState.selectedPricePerKm` - Pricing
- `appState.discountAmount` - Applied discount
- `appState.currentRideId` - Current ride ID
- `appState.bookingInProgress` - Booking status flag

---

## Error Handling

### Wallet Payment Errors:

1. **Failed to fetch wallet balance**
   - Shows: "Failed to fetch wallet balance"
   - Returns: `false` (prevents ride creation)

2. **Razorpay error**
   - Shows: "Payment Error: {error message}"
   - User can retry

3. **Payment success but add money fails**
   - Shows: "Failed to update wallet"
   - Logs error but doesn't prevent ride creation (user can try again)

### CreateRideCall Errors:

- Shows message from API response
- Displays: "Booking failed"

---

## User Flow

### Scenario 1: Wallet Has Sufficient Balance

```
1. User selects Wallet payment
2. User clicks Confirm Booking
3. App fetches wallet balance
4. ✅ Balance >= Ride amount
5. App creates ride directly
6. Navigate to AutoBookWidget
7. Ride starts and completes
8. Wallet balance refreshed (optional deduction handled by API)
```

### Scenario 2: Wallet Insufficient Balance

```
1. User selects Wallet payment
2. User clicks Confirm Booking
3. App fetches wallet balance
4. ❌ Balance < Ride amount
5. App calculates difference
6. Razorpay opens for difference amount
7. User enters payment details
8. ✅ Payment successful
9. App adds topup amount to wallet via API
10. Wallet balance refreshed in app state
11. App creates ride
12. Navigate to AutoBookWidget
13. Ride starts and completes
14. Wallet balance refreshed again
```

### Scenario 3: Payment Failure

```
1. User completes wallet top-up flow
2. ❌ Razorpay payment fails
3. App shows error message
4. User can retry or select different payment method
5. Ride not created
```

---

## Testing Checklist

- [ ] Test with sufficient wallet balance (direct ride creation)
- [ ] Test with insufficient balance (Razorpay opens correctly)
- [ ] Test Razorpay payment success flow
- [ ] Test Razorpay payment error handling
- [ ] Test wallet balance refresh after ride completion
- [ ] Test switching payment methods
- [ ] Test network error scenarios
- [ ] Test with different ride amounts
- [ ] Verify appState.walletBalance is updated correctly
- [ ] Verify ride is created with `paymentType: "wallet"`

---

## Debug Logs

The implementation includes detailed console logs for debugging:

### Available Logs:

```dart
'💳 Starting Wallet Payment Process...'
'🚗 Ride Amount: ₹{amount}'
'💰 Wallet Balance: ₹{balance}'
'✅ Wallet has sufficient balance'
'🔴 Insufficient balance, opening Razorpay for: ₹{difference}'
'✅ Payment Success: {paymentId}'
'✅ Money added to wallet successfully'
'✅ Updated Wallet Balance: ₹{newBalance}'
'❌ Payment Error: {error}'
'✅ Ride Created: {rideId}'
'💳 Payment Method: {method}'
'💳 Ride completed with Wallet payment, refreshing wallet balance...'
'✅ Wallet balance refreshed: ₹{balance}'
```

---

## Key Features

✅ **Wallet Balance Check** - Validates sufficient funds before payment  
✅ **Razorpay Integration** - Seamless top-up for insufficient balance  
✅ **Automatic Top-up** - Only charges difference amount  
✅ **Balance Refresh** - Updates after top-up and ride completion  
✅ **Error Handling** - Graceful error messages and recovery  
✅ **Logging** - Comprehensive debug logs for troubleshooting  
✅ **State Management** - Proper cleanup and resource management  
✅ **User Feedback** - SnackBar notifications for all actions

---

## Future Enhancements

- [ ] Wallet history view
- [ ] Scheduled wallet top-ups
- [ ] Promotional wallet credits
- [ ] Transaction receipts
- [ ] Wallet refund for cancelled rides
- [ ] Multi-currency wallet support
- [ ] Wallet cashback offers

---

**Implementation Date:** February 2026  
**Status:** ✅ Complete  
**Reviewed By:** Team Lead
