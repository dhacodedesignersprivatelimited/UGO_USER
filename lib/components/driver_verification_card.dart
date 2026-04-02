import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';

import '/core/app_config.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

/// Rapido-style driver verification card for Scan to Book
class DriverVerificationCard extends StatelessWidget {
  const DriverVerificationCard({
    super.key,
    required this.driverName,
    required this.vehicleNo,
    this.driverPhotoUrl,
    this.rating = 4.5,
    required this.fareEstimate,
    required this.onConfirmTap,
    this.isLoading = false,
  });

  final String driverName;
  final String vehicleNo;
  final String? driverPhotoUrl;
  final double rating;
  final double fareEstimate;
  final VoidCallback onConfirmTap;
  final bool isLoading;

  static const Color primaryOrange = Color(0xFFFF7B10);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: driverPhotoUrl != null && driverPhotoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: driverPhotoUrl!.startsWith('http')
                            ? driverPhotoUrl!
                            : '${AppConfig.instance.imageBaseUrl}$driverPhotoUrl',
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildPlaceholderAvatar(),
                        errorWidget: (_, __, ___) => _buildPlaceholderAvatar(),
                      )
                    : _buildPlaceholderAvatar(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicleNo,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: primaryOrange,
                        letterSpacing: 1.2,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    RatingBarIndicator(
                      rating: rating,
                      itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 18,
                      unratedColor: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Est. Fare', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    Text(
                      '₹${fareEstimate.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: primaryOrange),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verify bike number matches before starting',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FFButtonWidget(
                onPressed: isLoading ? null : onConfirmTap,
                text: isLoading ? 'Starting...' : 'Verify & Start Ride',
                icon: isLoading ? null : const Icon(Icons.check_circle, color: Colors.white, size: 22),
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 52,
                  color: Colors.green.shade600,
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  disabledColor: Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey.shade200,
      child: Icon(Icons.person, size: 36, color: Colors.grey.shade600),
    );
  }
}
