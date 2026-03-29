import 'package:flutter/foundation.dart';
import 'package:ugouser/home/home_widget.dart';
import 'package:ugouser/ride_session.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:ugouser/config/payment_config.dart';
import 'ridecomplet_model.dart';
export 'ridecomplet_model.dart';

String? _vehicleFromAdminVehicle(Map<String, dynamic>? d) {
  if (d == null) return null;
  final av = d['adminVehicle'];
  if (av is Map) return av['vehicle_name']?.toString();
  return null;
}

class RidecompletWidget extends StatefulWidget {
  const RidecompletWidget({
    super.key,
    this.onNext,
    this.pickupLocation,
    this.dropoffLocation,
    this.distance,
    this.duration,
    this.driverName,
    this.vehicleNumber,
    this.fare,
    this.fareAmount,
    this.driverDetails,
    this.rideId,
    this.userId,
    this.paymentMethod,
  });

  final VoidCallback? onNext;
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? distance;
  final String? duration;
  final String? driverName;
  final String? vehicleNumber;
  final String? fare;
  final Map<String, dynamic>? driverDetails;
  final int? rideId;
  final int? userId;
  final String? paymentMethod;
  final num? fareAmount;

  @override
  State<RidecompletWidget> createState() => _RidecompletWidgetState();
}

class _RidecompletWidgetState extends State<RidecompletWidget> {
  late RidecompletModel _model;
  final appState = FFAppState();
  late Razorpay _razorpay;

  int _rating = 0;
  Set<String> _selectedComments = {};
  bool _showFareBreakdown = false;
  bool _isSubmitting = false;
  bool _paymentProcessed = false;
  bool _paymentProcessing = false;
  bool _upiPaymentPending = false;

  static const Color primaryOrange = Color(0xFFFF6B35);

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RidecompletModel());
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayError);
    print('initState called with rideId: ${widget.rideId}');
    WidgetsBinding.instance.addPostFrameCallback((_) => _processPaymentOnComplete());
  }

  @override
  void dispose() {
    _razorpay.clear();
    _model.maybeDispose();
    super.dispose();
  }

  void _onRazorpaySuccess(PaymentSuccessResponse response) {
    print('✅ Razorpay success: ${response.paymentId}');
    _recordPaymentAfterUpiSuccess();
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    print('❌ Razorpay error: ${response.message}');
    if (mounted) {
      setState(() {
        _paymentProcessing = false;
        _upiPaymentPending = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response.message?.contains('cancel') == true
            ? 'Payment cancelled. Tap Pay to try again.'
            : 'Payment failed: ${response.message}'),
        backgroundColor: Colors.orange,
      ));
    }
  }

  Future<void> _recordPaymentAfterUpiSuccess() async {
    final rideId = widget.rideId ?? appState.currentRideId;
    final userId = widget.userId ?? appState.userid;
    final amount = widget.fareAmount ?? 0;
    if (rideId == null || userId == 0 || amount <= 0) return;
    try {
      final res = await CreatePaymentCall.call(
        rideId: rideId,
        userId: userId,
        amount: amount,
        paymentMethod: 'online',
        paymentStatus: 'success',
        token: appState.accessToken,
      );
      if (res.succeeded && mounted) {
        setState(() {
          _paymentProcessed = true;
          _paymentProcessing = false;
          _upiPaymentPending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Payment successful!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      print('❌ Record payment error: $e');
      if (mounted) setState(() => _paymentProcessing = false);
    }
  }

  Future<void> _processPaymentOnComplete() async {
    if (_paymentProcessed) return;
    final rideId = widget.rideId ?? appState.currentRideId;
    final userId = widget.userId ?? appState.userid;
    final method = (widget.paymentMethod ?? 'cash').toString().toLowerCase();
    final amount = widget.fareAmount ?? 0;
    if (rideId == null || userId == 0 || amount <= 0) return;

    switch (method) {
      case 'cash':
        try {
          final res = await CreatePaymentCall.call(
            rideId: rideId,
            userId: userId,
            amount: amount,
            paymentMethod: 'cash',
            paymentStatus: 'success',
            token: appState.accessToken,
          );
          if (res.succeeded && mounted) {
            setState(() => _paymentProcessed = true);
            print('✅ Cash payment recorded');
          }
        } catch (e) {
          print('❌ Cash payment record error: $e');
        }
        break;
      case 'wallet':
        try {
          final res = await PaymentProcessCall.call(
            rideId: rideId,
            paymentMethod: 'wallet',
            amount: amount,
            token: appState.accessToken,
          );
          if (res.succeeded && mounted) {
            setState(() => _paymentProcessed = true);
            appState.walletBalance = (appState.walletBalance - amount).clamp(0.0, double.infinity);
            print('✅ Wallet payment processed');
          } else {
            final fallback = await CreatePaymentCall.call(
              rideId: rideId,
              userId: userId,
              amount: amount,
              paymentMethod: 'wallet',
              paymentStatus: 'success',
              token: appState.accessToken,
            );
            if (fallback.succeeded && mounted) setState(() => _paymentProcessed = true);
          }
        } catch (e) {
          print('❌ Wallet payment error: $e');
          try {
            final fallback = await CreatePaymentCall.call(
              rideId: rideId,
              userId: userId,
              amount: amount,
              paymentMethod: 'wallet',
              paymentStatus: 'success',
              token: appState.accessToken,
            );
            if (fallback.succeeded && mounted) setState(() => _paymentProcessed = true);
          } catch (_) {}
        }
        break;
      case 'online':
      case 'upi':
        setState(() => _upiPaymentPending = true);
        break;
      default:
        try {
          final res = await CreatePaymentCall.call(
            rideId: rideId,
            userId: userId,
            amount: amount,
            paymentMethod: method,
            paymentStatus: 'success',
            token: appState.accessToken,
          );
          if (res.succeeded && mounted) setState(() => _paymentProcessed = true);
        } catch (_) {}
    }
  }

  Future<void> _payWithUpi() async {
    if (_paymentProcessed || _paymentProcessing) return;
    final rideId = widget.rideId ?? appState.currentRideId;
    final amount = widget.fareAmount ?? 0;
    if (rideId == null || amount <= 0) return;

    setState(() => _paymentProcessing = true);
    try {
      String? orderId;
      final processRes = await PaymentProcessCall.call(
        rideId: rideId,
        paymentMethod: 'upi',
        amount: amount,
        token: appState.accessToken,
      );
      orderId = PaymentProcessCall.razorpayOrderId(processRes.jsonBody);
      if (orderId == null || orderId.isEmpty) {
        final orderRes = await CreateRazorpayOrderCall.call(
          rideId: rideId,
          amount: amount,
          token: appState.accessToken,
        );
        orderId = CreateRazorpayOrderCall.orderId(orderRes.jsonBody);
      }
      if (orderId != null && orderId.isNotEmpty) {
        _razorpay.open({
          'key': PaymentConfig().getRazorpayKey(),
          'order_id': orderId,
          'name': 'Ugo Ride',
          'description': 'Ride payment',
          'prefill': {'contact': '', 'email': ''},
        });
      } else {
        _razorpay.open({
          'key': PaymentConfig().getRazorpayKey(),
          'amount': (amount * 100).round(),
          'name': 'Ugo Ride',
          'description': 'Ride payment',
          'prefill': {'contact': '', 'email': ''},
        });
      }
    } catch (e) {
      print('❌ Create order error: $e');
      if (mounted) {
        setState(() => _paymentProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not start payment: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  String _formatPaymentLabel(String? method) {
    if (method == null || method.isEmpty) return 'Cash';
    switch (method.toLowerCase()) {
      case 'wallet':
        return 'Wallet';
      case 'online':
        return 'UPI / Card';
      default:
        return 'Cash';
    }
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              Text('Please select a rating'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Safely get driver data (handles both wrapped {data: {...}} and flat format)
      final rawDriver = widget.driverDetails ?? RideSession().driverData;
      Map<String, dynamic>? driverData;

      if (rawDriver != null) {
        final dataField = rawDriver['data'];
        driverData = (dataField != null && dataField is Map)
            ? Map<String, dynamic>.from(dataField)
            : Map<String, dynamic>.from(rawDriver);
      }

      final driverId = driverData?['id'];

      // Safely get ride and user IDs
      final rawRideData = RideSession().rideData;

      if (rawRideData != null) {
        final dataField = rawRideData['data'];
        if (dataField != null && dataField is Map) {
        }
      }

      final rideId = widget.rideId ?? appState.currentRideId;
      final userId = widget.userId ?? appState.userid;

      // Check for null IDs before proceeding
      if (rideId == null || driverId == null) {
        print('❌ Error: One or more IDs are null.');
        print('   - rideId: $rideId');
        print('   - userId: $userId');
        print('   - driverId: $driverId');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not submit rating. Missing required ride information.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }

      // Prepare rating comment
      String ratingComment =
      _selectedComments.isEmpty ? '' : _selectedComments.join(', ');

      if (kDebugMode) {
        debugPrint('🎯 Submitting Rating:');
        debugPrint('   ride_id: $rideId');
        debugPrint('   user_id: $userId');
        debugPrint('   driver_id: $driverId');
        debugPrint('   rating_given_by: user');
        debugPrint('   rating_score: $_rating');
        debugPrint('   rating_comment: $ratingComment');
      }

      // Call API
      final response = await SubmitRideRatingCall.call(
        rideId: rideId,
        userId: userId,
        driverId: driverId,
        ratingGivenBy: 'user',
        ratingScore: _rating,
        ratingComment: ratingComment,
      );

     final isSuccess =
    response.succeeded ||
    SubmitRideRatingCall.success(response.jsonBody) == true ||
    SubmitRideRatingCall.statusCode(response.jsonBody) == 201;

if (isSuccess) {
        print('✅ Rating submitted successfully');
        print('   Response: ${response.jsonBody}');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rating submitted successfully!',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Navigate to next screen or home
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;

// Clear ride session if needed
            FFAppState().bookingInProgress = false;
            FFAppState().currentRideId = null;
            RideSession().clear();

            context.goNamed(HomeWidget.routeName);

        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Rating submission failed');
          debugPrint('   Status: ${response.statusCode}');
          debugPrint('   Response: ${response.jsonBody}');
        }

        final msg = getJsonField(response.jsonBody, r'''$.message''')?.toString();
        final isRateLimited = response.statusCode == 429;
        final userMsg = isRateLimited
            ? (msg?.isNotEmpty == true
                ? msg!
                : 'Too many requests. Please wait a few minutes, then try again.')
            : (msg?.isNotEmpty == true
                ? msg!
                : 'Failed to submit rating. Please try again.');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isRateLimited ? Icons.hourglass_bottom : Icons.error,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(userMsg)),
                ],
              ),
              backgroundColor:
                  isRateLimited ? const Color(0xFFE65100) : Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: isRateLimited ? 6 : 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Exception during rating submission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely get driver data (handles both wrapped {data: {...}} and flat format)
    final rawDriver = widget.driverDetails ?? RideSession().driverData;
    Map<String, dynamic>? driverData;

    if (rawDriver != null) {
      final dataField = rawDriver['data'];
      driverData = (dataField != null && dataField is Map)
          ? Map<String, dynamic>.from(dataField)
          : Map<String, dynamic>.from(rawDriver);
    }

    final driverName = (driverData != null)
        ? '${driverData['first_name'] ?? ''} ${driverData['last_name'] ?? ''}'
        .trim()
        : 'Driver';

    final vehicleType = driverData?['vehicle_type'] ??
        _vehicleFromAdminVehicle(driverData) ??
        'Auto';
    final driverRating = driverData?['driver_rating']?.toString() ??
        driverData?['rating']?.toString() ??
        '4.9';

    return Container(
      // backgroundColor: Colors.white,
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Driver Info Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Driver Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF5EB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 45,
                            color: primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Driver Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Driver',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                driverName,
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Rating : ',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Color(0xFF666666),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    driverRating,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Vehicle : ',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Color(0xFF666666),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    vehicleType,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Review Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Review',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Star Rating
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.star,
                              size: 48,
                              color: index < _rating
                                  ? Colors.amber
                                  : Color(0xFFE0E0E0),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Optional Comments
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Optional Comments',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Comment Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildCommentChip('Friendly'),
                        _buildCommentChip('Safe'),
                        _buildCommentChip('Worst'),
                        _buildCommentChip('Fast'),
                        _buildCommentChip('Affordable'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Total Fare Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showFareBreakdown = !_showFareBreakdown;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Fare',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  widget.fare ?? '₹${appState.selectedBaseFare.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _showFareBreakdown
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Color(0xFF333333),
                                  size: 24,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Fare Breakdown
                  if (_showFareBreakdown)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        margin: const EdgeInsets.only(top: 1),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFF9F9F9),
                          border: Border.all(color: Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildFareRow(
                              'Total Fare',
                              widget.fare ?? '₹${appState.selectedBaseFare.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 12),
                            Divider(color: Color(0xFFE0E0E0), thickness: 1),
                            const SizedBox(height: 12),
                            _buildFareRow('Payment Method',
                              _formatPaymentLabel(widget.paymentMethod ?? appState.selectedPaymentMethod),
                                isLast: true),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Pay Now button for UPI
                  if (_upiPaymentPending && !_paymentProcessed)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _paymentProcessing ? null : _payWithUpi,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            disabledBackgroundColor: primaryOrange.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _paymentProcessing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Pay ${widget.fare ?? "Now"}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  if (_upiPaymentPending && !_paymentProcessed)
                    const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || (_upiPaymentPending && !_paymentProcessed))
                      ? null
                      : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    disabledBackgroundColor: primaryOrange.withValues(alpha:0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Text(
                    'Submit',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentChip(String label) {
    final isSelected = _selectedComments.contains(label);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedComments.remove(label);
          } else {
            _selectedComments.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color:
          isSelected ? primaryOrange.withValues(alpha:0.1) : Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryOrange : Color(0xFFE0E0E0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? primaryOrange : Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  Widget _buildFareRow(String label, String value, {bool isLast = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: isLast ? FontWeight.w600 : FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}