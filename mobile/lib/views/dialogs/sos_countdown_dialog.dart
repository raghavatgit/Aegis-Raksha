import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/notification_service.dart';

class SosCountdownDialog {
  static void show(
    BuildContext context, {
    String initialNote = "",
    String initialType = AppConstants.typeSecurity,
    required Function(String type, String severity, String note) onConfirmed,
    VoidCallback? onCancelled,
  }) {
    String selectedType = initialType;
    String selectedSeverity = AppConstants.severityCritical;
    final noteController = TextEditingController(text: initialNote);
    int countdown = 5; // 5-second false alarm grace period
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (countdown > 1) {
                setDialogState(() {
                  countdown--;
                });
              } else {
                t.cancel();
                Navigator.of(dialogContext).pop();
                onConfirmed(selectedType, selectedSeverity, noteController.text.trim());
              }
            });

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlush,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: AppTheme.primaryBerry, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Emergency SOS",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          "Broadcasting to Mesh & Cloud",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // False alarm notice banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Color(0xFFF57F17), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "False Alarm? Tap Cancel below within $countdown seconds to abort.",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF5D4037),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Countdown Ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 86,
                          height: 86,
                          child: CircularProgressIndicator(
                            value: countdown / 5.0,
                            strokeWidth: 7,
                            backgroundColor: const Color(0xFFFCE4EC),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBerry),
                          ),
                        ),
                        Text(
                          "$countdown",
                          style: GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryBerry,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Incident Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      dropdownColor: Colors.white,
                      style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Incident Type",
                        labelStyle: GoogleFonts.poppins(color: const Color(0xFF757575), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: AppConstants.typeSecurity,
                          child: Text("👮 Physical Threat", overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: "WOMEN_SAFETY",
                          child: Text("🛡️ Women Safety", overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.typeMedical,
                          child: Text("🚑 Medical Emergency", overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.typeFire,
                          child: Text("🔥 Fire / Hazard", overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // User note input
                    TextField(
                      controller: noteController,
                      style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "e.g. Near metro exit, feeling unsafe",
                        hintStyle: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 12),
                        labelText: "Optional Note",
                        labelStyle: GoogleFonts.poppins(color: const Color(0xFF757575), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                Row(
                  children: [
                    // Prominent False Alarm Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF757575),
                          side: const BorderSide(color: Color(0xFFBDBDBD)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          timer?.cancel();
                          NotificationService.stopSirenSound();
                          Navigator.of(dialogContext).pop();
                          onCancelled?.call();
                        },
                        child: Text(
                          "CANCEL",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Urgent Direct Dispatch Now Button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBerry,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          timer?.cancel();
                          Navigator.of(dialogContext).pop();
                          onConfirmed(selectedType, selectedSeverity, noteController.text.trim());
                        },
                        child: Text(
                          "DISPATCH NOW",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
