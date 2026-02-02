import 'package:ugouser/ride_session.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
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
  

  @override
  State<RidecompletWidget> createState() => _RidecompletWidgetState();
}

class _RidecompletWidgetState extends State<RidecompletWidget>
    with SingleTickerProviderStateMixin {
  late RidecompletModel _model;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  static const Color primaryColor = Color(0xFFFF7B10);

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RidecompletModel());

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🧪 widget.driverDetails => ${widget.driverDetails}');
  print('🧪 RideSession.driverData => ${RideSession().driverData}');
   final driverData =
    widget.driverDetails ??
    RideSession().driverData ??
    const {
      'name': 'Driver not assigned',
      'vehicle_number': '--',
    };


final driverName =
    widget.driverName ??
    driverData['name'] ??
    driverData['first_name'] ??
    'Driver not assigned';

final vehicleNumber =
    widget.vehicleNumber ??
    driverData['vehicle_number'] ??
    '--';

 print('🧪 FINAL driverData => $driverData');
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(height: 60),

                    // Success Icon with Animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Ride Completed!',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Thank you for riding with us',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Trip Details Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Trip Details Header
                              Text(
                                'Trip Details',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Pickup Location
                              _buildLocationRow(
                                icon: Icons.radio_button_checked,
                                color: Colors.green,
                                label: 'Pickup',
                                location: widget.pickupLocation ?? 'MG Road',
                              ),

                              const SizedBox(height: 16),

                              // Dropoff Location
                              _buildLocationRow(
                                icon: Icons.location_on,
                                color: Colors.red,
                                label: 'Dropoff',
                                location: widget.dropoffLocation ?? 'HSR Layout',
                              ),

                              Divider(
                                height: 32,
                                thickness: 1,
                                color: Colors.grey[300],
                              ),

                              // Distance & Duration
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildInfoColumn(
                                    icon: Icons.straighten,
                                    label: 'Distance',
                                    value: widget.distance ?? '12.5 km',
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.grey[300],
                                  ),
                                  _buildInfoColumn(
                                    icon: Icons.access_time,
                                    label: 'Duration',
                                    value: widget.duration ?? '28 mins',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Driver Info Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: primaryColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                     driverName ?? 'Driver not assigned',


                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      // driverName,
                                         vehicleNumber,

                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.fare != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.fare!,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Rating Prompt (Optional)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber[700], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Rate your experience',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber[900],
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.amber[700],
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(24),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // View Trip Summary Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (widget.onNext != null) {
                          widget.onNext!();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'View Trip Summary',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Back to Home Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String label,
    required String location,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
