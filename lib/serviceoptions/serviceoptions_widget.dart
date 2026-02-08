import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'serviceoptions_model.dart';
export 'serviceoptions_model.dart';

/// 🚀 Modern Responsive Service Options
class ServiceoptionsWidget extends StatefulWidget {
  const ServiceoptionsWidget({super.key});

  static String routeName = 'serviceoptions';
  static String routePath = '/serviceoptions';

  @override
  State<ServiceoptionsWidget> createState() => _ServiceoptionsWidgetState();
}

class _ServiceoptionsWidgetState extends State<ServiceoptionsWidget> {
  late ServiceoptionsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ServiceoptionsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
       onWillPop: () async {
      // Navigate to Home instead of exiting
      context.pushNamed(HomeWidget.routeName);
      return false; // Prevent default pop (exit)
    },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFF7B10),
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FlutterFlowIconButton(
                borderColor: Colors.transparent,
                borderRadius: 30.0,
                borderWidth: 1.0,
                buttonSize: 44.0,
                fillColor: Colors.white.withOpacity(0.2), // ✅ Fixed background
                icon: const Icon(
                  Icons.arrow_back_rounded, // ✅ Fixed Icon widget
                  color: Colors.white,
                  size: 24.0,
                ),
                onPressed: () async {
                  context.pushNamed(HomeWidget.routeName);
        //                if (Navigator.of(context).canPop()) {
        //   Navigator.of(context).pop();
        // }
                },
              ),
            ),
            title: Text(
              FFLocalizations.of(context).getText('rnwdwckb' /* Services */),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [],
            centerTitle: true,
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isNarrow = screenWidth < 360;
                final padding = isNarrow ? 20.0 : 28.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(padding, 32, padding, 40),
                  child: Column(
                    children: [
                      // 1. Hero Header
                      _buildHeroHeader(isNarrow),

                      SizedBox(height: isNarrow ? 40 : 56),

                      // 2. Service Cards Grid
                      _buildServiceCards(isNarrow),

                      SizedBox(height: isNarrow ? 100 : 140),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   FFLocalizations.of(context).getText('xlfqyvqa' /* Comfortable Rides, Anytime */),
        //   style: GoogleFonts.poppins(
        //     fontSize: isNarrow ? 26 : 32,
        //     fontWeight: FontWeight.w700,
        //     color: Colors.black87,
        //     height: 1.2,
        //   ),
        // ),
        Text(
          'Comfortable Rides Anytime',
          style: GoogleFonts.inter(
            fontSize: isNarrow ? 20 : 22,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Choose your ride type below',
          style: GoogleFonts.inter(
            fontSize: isNarrow ? 16 : 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCards(bool isNarrow) {
    final serviceCards = [
      {
        'image': 'assets/images/bike.png',
        'label': FFLocalizations.of(context).getText('o76sscog' /* Book a bike */),
        'color': const Color(0xFF2196F3),
        // 'route': PlanYourRideWidget.routeName,
      },
      {
        'image': 'assets/images/auto.png',
        'label': FFLocalizations.of(context).getText('p3js2d3q' /* Book a auto */),
        'color': const Color(0xFF4CAF50),
        // 'route': PlanYourRideWidget.routeName,
      },
      {
        'image':"assets/images/car.png" , // Use icon instead
        'label': FFLocalizations.of(context).getText('a1vegvac' /* Book a Cab */),
        'color': const Color(0xFFFF9800),
        'icon': Icons.local_taxi,
        // 'route': PlanYourRideWidget.routeName,
      },
    ];

    return Column(
      children: List.generate(serviceCards.length, (index) {
        final card = serviceCards[index];

        return Padding(
          padding: EdgeInsets.only(bottom: isNarrow ? 16 : 20),
          child: _buildServiceCard(
            image: card['image'] as String?,
            label: card['label'] as String,
            color: card['color'] as Color,
            icon: card['icon'] as IconData?,
            // route: card['route'] as String,
            isNarrow: isNarrow,
          ),
        );
      }),
    );
  }

  Widget _buildServiceCard({
    String? image,
    required String label,
    required Color color,
    IconData? icon,
    // required String route,
    required bool isNarrow,
  }) {
    return GestureDetector(
      onTap: () {
  if (label.toLowerCase().contains('auto')) {
    // ✅ Auto → Where to go
    context.pushNamed(PlanYourRideWidget.routeName);
  } else {
    // 🚧 Bike & Car → Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label rides coming soon',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
},

      child: Container(
        height: isNarrow ? 88 : 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 20 : 24,
            vertical: isNarrow ? 16 : 20,
          ),
          child: Row(
            children: [
              // Icon/Image Container
              Container(
                width: isNarrow ? 52 : 60,
                height: isNarrow ? 52 : 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: image != null
                      ? Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.two_wheeler,
                      color: Colors.white,
                      size: 28,
                    ),
                  )
                      : icon != null
                      ? Icon(
                    icon,
                    color: Colors.white,
                    size: isNarrow ? 28 : 32,
                  )
                      : const SizedBox(),
                ),
              ),

              SizedBox(width: isNarrow ? 16 : 20),

              // Label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: isNarrow ? 18 : 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Quick booking',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
