import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/emergency_alert.dart';
import '../../services/emergency_services_dispatcher.dart';

class SavedAlertsList extends StatelessWidget {
  final List<EmergencyAlert> savedAlerts;
  final VoidCallback? onPreloadDemo;
  final VoidCallback? onClear;

  const SavedAlertsList({
    super.key,
    required this.savedAlerts,
    this.onPreloadDemo,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Alerts Log (${savedAlerts.length})",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (savedAlerts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFFBDBDBD), size: 38),
                const SizedBox(height: 8),
                Text(
                  "No emergency alerts recorded",
                  style: GoogleFonts.poppins(
                    color: AppTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "When an SOS is broadcast or received from nearby mesh phones, it will appear here.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF757575),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedAlerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final alert = savedAlerts[index];
              final lat = (alert.location['lat'] as num?)?.toDouble() ?? 0.0;
              final lng = (alert.location['lng'] as num?)?.toDouble() ?? 0.0;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: alert.isSynced ? const Color(0xFFEEEEEE) : AppTheme.primaryBerry.withOpacity(0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                alert.alertType,
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryBerry,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: alert.isSynced ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                alert.isSynced ? "Cloud Synced" : "Mesh Queued",
                                style: GoogleFonts.poppins(
                                  color: alert.isSynced ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          alert.timestamp.length > 16 ? alert.timestamp.substring(11, 16) : alert.timestamp,
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.description,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF757575)),
                        const SizedBox(width: 4),
                        Text(
                          "GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}",
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                        ),
                        const Spacer(),
                        if (lat != 0.0 && lng != 0.0)
                          InkWell(
                            onTap: () => EmergencyServicesDispatcher.openLocationInMaps(lat: lat, lng: lng),
                            child: Row(
                              children: [
                                const Icon(Icons.map_outlined, size: 14, color: AppTheme.primaryBerry),
                                const SizedBox(width: 4),
                                Text(
                                  "View Map",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBerry,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
