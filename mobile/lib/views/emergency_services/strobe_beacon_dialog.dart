import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class StrobeBeaconDialog extends StatefulWidget {
  const StrobeBeaconDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const StrobeBeaconDialog(),
    );
  }

  @override
  State<StrobeBeaconDialog> createState() => _StrobeBeaconDialogState();
}

class _StrobeBeaconDialogState extends State<StrobeBeaconDialog> {
  Timer? _strobeTimer;
  bool _isRed = true;
  bool _sirenSoundOn = true;

  @override
  void initState() {
    super.initState();
    NotificationService.playSirenSound();
    _strobeTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (mounted) {
        setState(() {
          _isRed = !_isRed;
        });
      }
    });
  }

  @override
  void dispose() {
    _strobeTimer?.cancel();
    NotificationService.stopSirenSound();
    super.dispose();
  }

  void _toggleSiren() {
    setState(() {
      _sirenSoundOn = !_sirenSoundOn;
      if (_sirenSoundOn) {
        NotificationService.playSirenSound();
      } else {
        NotificationService.stopSirenSound();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _isRed ? const Color(0xFFFF0D36) : const Color(0xFF0055FF);

    return Scaffold(
      backgroundColor: currentColor,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.yellowAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "POLICE RESCUE BEACON ACTIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Center Icon & Visual Beacon
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.95),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 40,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRed ? Icons.local_police : Icons.shield_rounded,
                      size: 70,
                      color: currentColor,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isRed ? "🚨 POLICE STROBE (RED)" : "🛡️ RESCUE BEACON (BLUE)",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Hold phone upright so emergency responders and police can pinpoint you in the dark.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Bottom Actions
              Column(
                children: [
                  // Siren Sound Toggle
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _toggleSiren,
                    icon: Icon(_sirenSoundOn ? Icons.volume_up : Icons.volume_off, color: Colors.yellowAccent),
                    label: Text(_sirenSoundOn ? "Mute Siren Audio" : "Play Siren Audio"),
                  ),
                  const SizedBox(height: 16),

                  // Stop Beacon Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close, size: 24, color: Colors.red),
                      label: const Text(
                        "TURN OFF BEACON",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
