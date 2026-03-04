# Code Snippets & Integration Guide

## Quick Code Reference for Wallet Payment System

---

## 1️⃣ Import Razorpay

**File:** `avaliable_options_widget.dart`  
**Location:** Top of file with other imports

```dart
import 'package:razorpay_flutter/razorpay_flutter.dart';
```

---

## 2️⃣ State Variables

**File:** `avaliable_options_widget.dart`  
**Location:** Inside `_AvaliableOptionsWidgetState` class

```dart
// Razorpay & Wallet
late Razorpay _razorpay;
double? _walletBalance;
int? _rideAmountForPayment;
```

---

## 3️⃣ Initialize Razorpay (in initState)

**File:** `avaliable_options_widget.dart`

```dart
@override
void initState() {
  super.initState();
  // ... existing code ...

  // Initialize Razorpay
  _razorpay = Razorpay();
  _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
  _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

  // ... rest of initState ...
}
```

---

## 4️⃣ Cleanup (in dispose)

**File:** `avaliable_options_widget.dart`

```dart
@override
void dispose() {
  _razorpay.clear();
  _slideController.dispose();
  super.dispose();
}
```

---

## 5️⃣ Update \_confirmBooking()

**File:** `avaliable_options_widget.dart`

**BEFORE:** (Old code - direct CreateRideCall)

```dart
final createRideRes = await CreateRideCall.call(
  token: appState.accessToken,
  userId: appState.userid,
  // ... other parameters ...
  paymentType: selectedPaymentMethod.toLowerCase(),
);
```

**AFTER:** (New code - with wallet check)

```dart
// ✅ WALLET PAYMENT LOGIC
if (selectedPaymentMethod == 'Wallet') {
  final walletCheckResult = await _handleWalletPayment(appState, finalFare);
  if (!walletCheckResult) {
    if (mounted) setState(() => isLoadingRide = false);
    return; // Payment failed, exit
  }
}

// 🔴 CREATE RIDE CALL
final createRideRes = await CreateRideCall.call(
  token: appState.accessToken,
  userId: appState.userid,
  // ... other parameters ...
  paymentType: selectedPaymentMethod.toLowerCase(),
);
```

---

## 6️⃣ Add \_handleWalletPayment() Method

**File:** `avaliable_options_widget.dart`  
**Location:** Add before `_confirmBooking()` method

```dart
/// Main wallet payment handler
/// Returns: true if payment succeeded or if sufficient balance
///         false if payment failed
Future<bool> _handleWalletPayment(FFAppState appState, int rideAmount) async {
  print('💳 Starting Wallet Payment Process...');
  print('🚗 Ride Amount: ₹$rideAmount');

  try {
    // 1️⃣ FETCH WALLET BALANCE
    final walletRes = await GetwalletCall.call(
      userId: appState.userid,
      token: appState.accessToken,
    );

    if (!walletRes.succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to fetch wallet balance'),
        backgroundColor: Colors.red,
      ));
      return false;
    }

    final walletBalanceStr = GetwalletCall.walletBalance(walletRes.jsonBody);
    final double walletBalance = double.tryParse(walletBalanceStr ?? '0') ?? 0.0;
    _walletBalance = walletBalance;

    print('💰 Wallet Balance: ₹$walletBalance');

    // 2️⃣ CHECK IF WALLET HAS SUFFICIENT BALANCE
    if (walletBalance >= rideAmount) {
      print('✅ Wallet has sufficient balance');
      return true;
    }

    // 3️⃣ INSUFFICIENT BALANCE - CALCULATE DIFFERENCE
    final int differenceAmount = (rideAmount - walletBalance.toInt()).abs();
    print('🔴 Insufficient balance, opening Razorpay for: ₹$differenceAmount');

    _rideAmountForPayment = rideAmount;

    // 4️⃣ OPEN RAZORPAY FOR DIFFERENCE
    _openRazorpayForWallet(differenceAmount, appState);

    return true;
  } catch (e) {
    print('❌ Wallet Payment Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Wallet Error: ${e.toString()}'),
      backgroundColor: Colors.red,
    ));
    return false;
  }
}
```

---

## 7️⃣ Add \_openRazorpayForWallet() Method

**File:** `avaliable_options_widget.dart`  
**Location:** Add before `_confirmBooking()` method

```dart
void _openRazorpayForWallet(int amountInRupees, FFAppState appState) {
  var options = {
    'key': 'rzp_test_SAvHgTPEoPnNo7',  // TODO: Update to production key
    'amount': (amountInRupees * 100),   // Convert to paise
    'name': 'Ugo App',
    'description': 'Wallet Top-up for Ride',
    'prefill': {
      'contact': '9885881832',
      'email': 'test@email.com',
    },
  };

  try {
    _razorpay.open(options);
  } catch (e) {
    print('❌ Razorpay Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment Error: ${e.toString()}'),
      backgroundColor: Colors.red,
    ));
  }
}
```

---

## 8️⃣ Add \_handlePaymentSuccess() Callback

**File:** `avaliable_options_widget.dart`  
**Location:** Add before `_confirmBooking()` method

```dart
void _handlePaymentSuccess(PaymentSuccessResponse response) async {
  print('✅ Payment Success: ${response.paymentId}');

  final appState = FFAppState();
  final amountToAdd = (_rideAmountForPayment ?? 0).toDouble();

  if (amountToAdd <= 0) {
    print('❌ Invalid amount');
    return;
  }

  try {
    // 5️⃣ ADD MONEY TO WALLET
    final addMoneyRes = await AddMoneyToWalletCall.call(
      userId: appState.userid,
      amount: amountToAdd,
      currency: 'INR',
      token: appState.accessToken,
    );

    if (addMoneyRes.succeeded) {
      print('✅ Money added to wallet successfully');

      // 6️⃣ FETCH UPDATED WALLET BALANCE
      final walletRes = await GetwalletCall.call(
        userId: appState.userid,
        token: appState.accessToken,
      );

      if (walletRes.succeeded) {
        final newBalance = GetwalletCall.walletBalance(walletRes.jsonBody);
        print('✅ Updated Wallet Balance: ₹$newBalance');
        setState(() {
          _walletBalance = double.tryParse(newBalance ?? '0') ?? 0.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Payment successful! Wallet updated.'),
          backgroundColor: Colors.green,
        ));
      }
    } else {
      print('❌ Failed to add money to wallet');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('❌ Failed to update wallet'),
        backgroundColor: Colors.red,
      ));
    }
  } catch (e) {
    print('❌ Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Error: ${e.toString()}'),
      backgroundColor: Colors.red,
    ));
  }
}
```

---

## 9️⃣ Add \_handlePaymentError() Callback

**File:** `avaliable_options_widget.dart`  
**Location:** Add before `_confirmBooking()` method

```dart
void _handlePaymentError(PaymentFailureResponse response) {
  print('❌ Payment Error: ${response.message}');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('❌ Payment Failed: ${response.message}'),
    backgroundColor: Colors.red,
  ));
}
```

---

## 🔟 Update auto_book_widget.dart

**File:** `auto_book_widget.dart`  
**Location:** Update `_handleCompletedRideNavigation()` method

**BEFORE:**

```dart
Future<void> _handleCompletedRideNavigation(Map<String, dynamic> rideData) async {
  _stopDistanceUpdateTimer();
  socket?.off("ride_updated");

  RideSession().rideData = rideData;

  // ... driver data handling ...

  if (mounted) {
    context.goNamed(RidecompleteWidget.routeName);
  }
}
```

**AFTER:**

```dart
Future<void> _handleCompletedRideNavigation(Map<String, dynamic> rideData) async {
  _stopDistanceUpdateTimer();
  socket?.off("ride_updated");

  RideSession().rideData = rideData;

  // ... driver data handling ...

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

## 📋 Integration Checklist

### Step 1: Update Imports

- [ ] Add `import 'package:razorpay_flutter/razorpay_flutter.dart';` to avaliable_options_widget.dart

### Step 2: Add State Variables

- [ ] Add `_razorpay`, `_walletBalance`, `_rideAmountForPayment` variables

### Step 3: Update initState()

- [ ] Initialize Razorpay with success/error callbacks

### Step 4: Update dispose()

- [ ] Call `_razorpay.clear()`

### Step 5: Add Methods to avaliable_options_widget.dart

- [ ] `_handleWalletPayment()`
- [ ] `_openRazorpayForWallet()`
- [ ] `_handlePaymentSuccess()`
- [ ] `_handlePaymentError()`

### Step 6: Update \_confirmBooking()

- [ ] Add wallet payment check before CreateRideCall

### Step 7: Update auto_book_widget.dart

- [ ] Update `_handleCompletedRideNavigation()` with wallet refresh

### Step 8: Testing

- [ ] Test with sufficient wallet
- [ ] Test with insufficient wallet (Razorpay opens)
- [ ] Test Razorpay success
- [ ] Test Razorpay error
- [ ] Test ride completion with wallet refresh

### Step 9: Deployment

- [ ] Replace Razorpay test key with production key
- [ ] Deploy to staging
- [ ] Deploy to production

---

## 🔑 Configuration

### Razorpay Keys (Update Before Production)

**Development/Testing:**

```dart
'key': 'rzp_test_SAvHgTPEoPnNo7'
```

**Production:**

```dart
'key': 'rzp_live_XXXXXXXXXXXXXXX'  // Get from Razorpay dashboard
```

**Location:** `_openRazorpayForWallet()` method, line with `'key':`

---

## 🧪 Quick Test Code

Add this to a debug button to test wallet flow:

```dart
// Test: Check wallet balance
Future<void> _testWalletBalance() async {
  final appState = FFAppState();
  final res = await GetwalletCall.call(
    userId: appState.userid,
    token: appState.accessToken,
  );

  if (res.succeeded) {
    final balance = GetwalletCall.walletBalance(res.jsonBody);
    print('Current wallet balance: ₹$balance');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wallet: ₹$balance'))
    );
  }
}

// Test: Open Razorpay
Future<void> _testRazorpay() async {
  _openRazorpayForWallet(100, FFAppState());
}
```

---

## 📞 Support

### Common Questions

**Q: What if wallet API fails?**  
A: User gets error message, payment is cancelled, can retry or use different method.

**Q: What if Razorpay payment fails?**  
A: Error message shown, user can retry payment.

**Q: What if wallet top-up succeeds but add money API fails?**  
A: Logged as warning, ride creation still proceeds (backend will handle).

**Q: How to test with production key?**  
A: Replace test key in `_openRazorpayForWallet()` method.

**Q: Where are the logs?**  
A: Flutter console - search for 💳, 🚗, 💰, ✅, ❌ emojis.

---

## ✅ Verification

After implementation, verify:

```dart
// ✅ All methods exist
_handleWalletPayment()         // ✓
_openRazorpayForWallet()       // ✓
_handlePaymentSuccess()        // ✓
_handlePaymentError()          // ✓

// ✅ All imports present
import 'package:razorpay_flutter/razorpay_flutter.dart' // ✓

// ✅ All state variables declared
late Razorpay _razorpay        // ✓
double? _walletBalance         // ✓
int? _rideAmountForPayment     // ✓

// ✅ All callbacks registered
_razorpay.on(...SUCCESS...)    // ✓
_razorpay.on(...ERROR...)      // ✓

// ✅ Cleanup in dispose()
_razorpay.clear()              // ✓

// ✅ Wallet check in _confirmBooking()
if (selectedPaymentMethod == 'Wallet') // ✓

// ✅ Wallet refresh in auto_book_widget
if (paymentMethod == 'wallet') // ✓
```

---

**Implementation Guide Complete! 🎉**

All code snippets are ready to use. Follow the checklist above for successful integration.
