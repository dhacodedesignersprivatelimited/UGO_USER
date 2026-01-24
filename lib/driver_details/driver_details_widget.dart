import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/backend/api_requests/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'driver_details_model.dart';
export 'driver_details_model.dart';

class DriverDetailsWidget extends StatefulWidget {
  const DriverDetailsWidget({
    super.key,
    required this.driverId,
    this.dropLocation,
    this.dropDistance,
    this.tripAmount,
  });

  final dynamic driverId;
  final String? dropLocation;
  final String? dropDistance;
  final double? tripAmount;

  static String routeName = 'Driver_details';
  static String routePath = '/driverDetails';

  @override
  State<DriverDetailsWidget> createState() => _DriverDetailsWidgetState();
}

class _DriverDetailsWidgetState extends State<DriverDetailsWidget> {
  late DriverDetailsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  dynamic _driverData;
  int _selectedTip = 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DriverDetailsModel());
    _fetchDriverDetails();
  }

  Future<void> _fetchDriverDetails() async {
    try {
      final response = await GetDriverDetailsCall.call(
        driverId: widget.driverId,
        token: FFAppState().accessToken,
      );
      if (mounted) {
        setState(() {
          if (response.succeeded) {
            _driverData = response.jsonBody;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFF7B10))));
    }

    final driverName = GetDriverDetailsCall.name(_driverData) ?? 'Sharath';
    final vehicleNum = GetDriverDetailsCall.vehicleNumber(_driverData) ?? '1287737738';
    final rating = GetDriverDetailsCall.rating(_driverData) ?? '4.7';
    final profileImg = GetDriverDetailsCall.profileImage(_driverData);
    
    final dropLoc = widget.dropLocation ?? FFAppState().droplocation ?? 'Ameerpet';
    final dropDist = widget.dropDistance ?? '15km';
    final baseAmount = widget.tripAmount ?? 100.0;
    final totalAmount = baseAmount + _selectedTip;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7B10),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'UGO',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  'T  A  X  I',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Driver Image
                          Center(
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: profileImg != null 
                                  ? Image.network(profileImg, fit: BoxFit.cover)
                                  : Image.asset('assets/images/0l6yw6.png', fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Driver details',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow('Driver name', driverName),
                          _buildDetailRow('vehicle number', vehicleNum),
                          Row(
                            children: [
                              Text(
                                'Rating : ',
                                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                              ),
                              const Icon(Icons.star, color: Color(0xFFFFDE14), size: 20),
                              Text(
                                ' $rating',
                                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('Drop location', dropLoc),
                          _buildDetailRow('Drop distance', dropDist),
                          const SizedBox(height: 16),
                          _buildDetailRow('Trip amount', '₹${baseAmount.toStringAsFixed(2)}'),
                          const SizedBox(height: 20),
                          Text(
                            'TIP AMOUNT',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTipButton(10),
                              _buildTipButton(20),
                              _buildTipButton(30),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total amount',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: const Color(0xFF2D7E20),
                                  ),
                                ),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2D7E20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: FFButtonWidget(
                        onPressed: () => Navigator.pop(context),
                        text: 'Cancel',
                        options: FFButtonOptions(
                          height: 56,
                          color: const Color(0xFFF01C1C),
                          textStyle: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FFButtonWidget(
                        onPressed: () async {
                          context.pushNamed(AutoBookWidget.routeName, queryParameters: {
                            'rideId': '0', // Replace with real ride ID if available
                          });
                        },
                        text: 'Continue',
                        options: FFButtonOptions(
                          height: 56,
                          color: const Color(0xFFFF7B10),
                          textStyle: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
          children: [
            TextSpan(text: '$label : '),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipButton(int amount) {
    final isSelected = _selectedTip == amount;
    return InkWell(
      onTap: () => setState(() => _selectedTip = isSelected ? 0 : amount),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.23,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1E6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Center(
          child: Text(
            amount.toString(),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFFFF7B10) : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
