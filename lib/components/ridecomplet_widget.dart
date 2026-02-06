import 'package:ugouser/home/home_widget.dart';
import 'package:ugouser/ride_session.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ridecomplet_model.dart';
export 'ridecomplet_model.dart';

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
    this.driverDetails,
    this.rideId,
    this.userId,
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

  @override
  State<RidecompletWidget> createState() => _RidecompletWidgetState();
}

class _RidecompletWidgetState extends State<RidecompletWidget> {
  late RidecompletModel _model;
  final appState = FFAppState();

  int _rating = 0;
  Set<String> _selectedComments = {};
  bool _showFareBreakdown = false;
  bool _isSubmitting = false;

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
    print('initState called with rideId: ${widget.rideId}');
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
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
      // Safely get driver data
      final rawDriver = widget.driverDetails ?? RideSession().driverData;
      Map<String, dynamic>? driverData;

      if (rawDriver != null) {
        final dataField = rawDriver['data'];
        if (dataField != null && dataField is Map) {
          driverData = dataField as Map<String, dynamic>;
        }
      }

      final driverId = driverData?['id'];

      // Safely get ride and user IDs
      final rawRideData = RideSession().rideData;
      Map<String, dynamic>? rideDetails;

      if (rawRideData != null) {
        final dataField = rawRideData['data'];
        if (dataField != null && dataField is Map) {
          rideDetails = dataField as Map<String, dynamic>;
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

      print('🎯 Submitting Rating:');
      print('   ride_id: $rideId');
      print('   user_id: $userId');
      print('   driver_id: $driverId');
      print('   rating_given_by: user');
      print('   rating_score: $_rating');
      print('   rating_comment: $ratingComment');

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
            RideSession().clear();

            context.pushNamed(HomeWidget.routeName);

        }
      } else {
        print('❌ Rating submission failed');
        print('   Status: ${response.statusCode}');
        print('   Response: ${response.jsonBody}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Failed to submit rating. Please try again.'),
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
    // Safely get driver data for display
    final rawDriver = widget.driverDetails ?? RideSession().driverData;
    Map<String, dynamic>? driverData;

    if (rawDriver != null) {
      final dataField = rawDriver['data'];
      if (dataField != null && dataField is Map) {
        driverData = dataField as Map<String, dynamic>;
      }
    }

    final driverName = (driverData != null)
        ? '${driverData['first_name'] ?? ''} ${driverData['last_name'] ?? ''}'
        .trim()
        : 'Driver';

    final vehicleType = driverData?['vehicle_type'] ?? 'Auto';
    final driverRating = driverData?['rating']?.toString() ?? '4.9';

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
                            _buildFareRow('Payment Method', 'Cash',
                                isLast: true),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
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
                  color: Colors.black.withOpacity(0.05),
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
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    disabledBackgroundColor: primaryOrange.withOpacity(0.6),
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
          isSelected ? primaryOrange.withOpacity(0.1) : Color(0xFFF5F5F5),
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