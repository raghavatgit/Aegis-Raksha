import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/location_helper.dart';
import '../../data/local/hive_storage_service.dart';
import '../../services/emergency_services_dispatcher.dart';
import '../../services/notification_service.dart';
import 'strobe_beacon_dialog.dart';

class EmergencyServicesScreen extends StatefulWidget {
  const EmergencyServicesScreen({super.key});

  @override
  State<EmergencyServicesScreen> createState() => _EmergencyServicesScreenState();
}

class _EmergencyServicesScreenState extends State<EmergencyServicesScreen> {
  List<Map<String, String>> _contacts = [];
  bool _isSirenPlaying = false;
  bool _isDispatching = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    setState(() {
      _contacts = HiveStorageService.getEmergencyContacts();
    });
  }

  Future<void> _dialService(EmergencyServiceType service) async {
    final success = await EmergencyServicesDispatcher.dialService(service);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not open dialer for ${service.code}"),
          backgroundColor: AppTheme.primaryBerry,
        ),
      );
    }
  }

  Future<void> _sendGpsSms(String recipientNumber, String serviceName) async {
    try {
      final loc = await LocationHelper.getCurrentCoordinates();
      final success = await EmergencyServicesDispatcher.sendEmergencySms(
        recipient: recipientNumber,
        lat: loc['lat'] ?? 0.0,
        lng: loc['lng'] ?? 0.0,
        emergencyType: serviceName,
        note: "Immediate emergency assistance requested at this location.",
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not open SMS for $recipientNumber"),
            backgroundColor: AppTheme.primaryBerry,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error fetching GPS location: $e"),
            backgroundColor: AppTheme.primaryBerry,
          ),
        );
      }
    }
  }

  Future<void> _fileUrgentPoliceTicket() async {
    setState(() => _isDispatching = true);
    try {
      final loc = await LocationHelper.getCurrentCoordinates();
      final ticketId = "POLICE_TICKET_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";

      final filed = await EmergencyServicesDispatcher.fileEmergencyDispatchTicket(
        ticketId: ticketId,
        serviceType: EmergencyServiceType.police112,
        lat: loc['lat'] ?? 0.0,
        lng: loc['lng'] ?? 0.0,
        description: "Urgent Citizen SOS: Immediate Police dispatch requested via Raksha-Net.",
      );

      if (mounted) {
        setState(() => _isDispatching = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.local_police, color: AppTheme.primaryBerry),
                const SizedBox(width: 8),
                Text(
                  "Dispatch Ticket Filed",
                  style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filed
                      ? "Ticket #$ticketId submitted to Police Control Room Realtime Queue."
                      : "Network offline. Ticket queued locally for immediate sync.",
                  style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  "GPS: ${loc['lat']?.toStringAsFixed(4)}, ${loc['lng']?.toStringAsFixed(4)}",
                  style: GoogleFonts.poppins(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Text(
                  "Would you like to dial Police 112 right now?",
                  style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Close", style: GoogleFonts.poppins(color: AppTheme.textMuted)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBerry,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  EmergencyServicesDispatcher.dialNumber('112');
                },
                icon: const Icon(Icons.call, size: 16),
                label: Text("Dial 112", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isDispatching = false);
    }
  }

  void _toggleSiren() {
    setState(() {
      _isSirenPlaying = !_isSirenPlaying;
      if (_isSirenPlaying) {
        NotificationService.playSirenSound();
      } else {
        NotificationService.stopSirenSound();
      }
    });
  }

  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Add Emergency Contact",
          style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                labelText: "Name (e.g. Mother, Sister)",
                labelStyle: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                labelText: "Phone Number",
                labelStyle: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: relationCtrl,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                labelText: "Relation / Priority Note",
                labelStyle: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBerry,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                await HiveStorageService.saveEmergencyContact(
                  nameCtrl.text.trim(),
                  phoneCtrl.text.trim(),
                  relationCtrl.text.trim().isEmpty ? "Emergency Guardian" : relationCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                _loadContacts();
              }
            },
            child: Text("Save Contact", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. National Emergency 112 Hero Card (Berry-Crimson Gradient)
          _buildNational112HeroCard(),
          const SizedBox(height: 22),

          // 2. Direct Emergency Services Grid (Police, Women, Medical, Fire)
          Text(
            "Emergency Helplines",
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "One-tap rapid call and location dispatch to emergency responders",
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.25,
            children: [
              _buildServiceGridItem(
                service: EmergencyServiceType.police100,
                color: AppTheme.policeBlue,
                icon: Icons.local_police,
              ),
              _buildServiceGridItem(
                service: EmergencyServiceType.womenHelpline,
                color: AppTheme.primaryBerry,
                icon: Icons.female,
              ),
              _buildServiceGridItem(
                service: EmergencyServiceType.ambulance108,
                color: AppTheme.safeGreen,
                icon: Icons.emergency,
              ),
              _buildServiceGridItem(
                service: EmergencyServiceType.fire101,
                color: const Color(0xFFF97316),
                icon: Icons.local_fire_department,
              ),
              _buildServiceGridItem(
                service: EmergencyServiceType.childline1098,
                color: const Color(0xFF8B5CF6),
                icon: Icons.child_care,
              ),
              _buildServiceGridItem(
                service: EmergencyServiceType.disaster1070,
                color: const Color(0xFF06B6D4),
                icon: Icons.flood,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Tactical On-Ground Deterrent & Beacon Tools
          Text(
            "Tactical Tools",
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Audible siren alarm and optical nighttime beacon",
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Siren Button
              Expanded(
                child: _buildTacticalToolCard(
                  title: _isSirenPlaying ? "STOP SIREN" : "LOUD SIREN",
                  subtitle: "High-Pitch Alarm",
                  icon: _isSirenPlaying ? Icons.volume_off : Icons.volume_up,
                  color: _isSirenPlaying ? AppTheme.primaryBerry : AppTheme.lightBlush,
                  isActive: _isSirenPlaying,
                  onTap: _toggleSiren,
                ),
              ),
              const SizedBox(width: 10),
              // Strobe Beacon Button
              Expanded(
                child: _buildTacticalToolCard(
                  title: "RESCUE BEACON",
                  subtitle: "Flashing Light",
                  icon: Icons.flash_on_rounded,
                  color: AppTheme.lightBlush,
                  isActive: false,
                  onTap: () => StrobeBeaconDialog.show(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Personal Guardians & Emergency Contacts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Emergency Contacts",
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    "Trusted contacts alerted with your live GPS location",
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.lightBlush,
                  foregroundColor: AppTheme.primaryBerry,
                ),
                icon: const Icon(Icons.add, size: 20),
                onPressed: _showAddContactDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildEmergencyContactsList(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildNational112HeroCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFB80046), Color(0xFF880E4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBerry.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "ALL-IN-ONE EMERGENCY",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "DIAL: 112",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "National Emergency (112)",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Unified police, medical, and fire dispatch with automated GPS location.",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Direct Call 112
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryBerry,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => EmergencyServicesDispatcher.dialNumber('112'),
                  icon: const Icon(Icons.call, size: 18),
                  label: Text(
                    "Call 112 Now",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Send GPS SMS to 112
              Expanded(
                flex: 5,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _sendGpsSms('112', 'NATIONAL_112_POLICE'),
                  icon: const Icon(Icons.message, size: 18),
                  label: Text(
                    "SMS Live GPS",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.9),
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              onPressed: _isDispatching ? null : _fileUrgentPoliceTicket,
              icon: _isDispatching
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 16),
              label: Text(
                _isDispatching ? "Submitting Dispatch Ticket..." : "File Digital Dispatch Ticket with Police Cloud",
                style: GoogleFonts.poppins(fontSize: 11, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceGridItem({
    required EmergencyServiceType service,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.blushPink.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service.code,
                  style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.shortName,
                style: GoogleFonts.poppins(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                service.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _dialService(service),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.call, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          "Call",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _sendGpsSms(service.code, service.title),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlush,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.send_rounded, size: 13, color: AppTheme.primaryBerry),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.lightBlush : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.primaryBerry : AppTheme.blushPink.withOpacity(0.5),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryBerry : AppTheme.lightBlush,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isActive ? Colors.white : AppTheme.primaryBerry, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: isActive ? AppTheme.primaryBerry : AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactsList() {
    if (_contacts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.blushPink.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            const Icon(Icons.contact_phone_outlined, color: AppTheme.textMuted, size: 36),
            const SizedBox(height: 8),
            Text(
              "No personal emergency contacts added yet.",
              style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _contacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, index) {
        final contact = _contacts[index];
        final name = contact['name'] ?? 'Guardian';
        final phone = contact['phone'] ?? '';
        final relation = contact['relation'] ?? 'Emergency Contact';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.blushPink.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.lightBlush,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'G',
                  style: GoogleFonts.poppins(color: AppTheme.primaryBerry, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "$phone • $relation",
                      style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call, color: AppTheme.safeGreen, size: 20),
                onPressed: () => EmergencyServicesDispatcher.dialNumber(phone),
              ),
              IconButton(
                icon: const Icon(Icons.message, color: AppTheme.primaryBerry, size: 20),
                onPressed: () => _sendGpsSms(phone, "GUARDIAN_ALERT"),
              ),
            ],
          ),
        );
      },
    );
  }
}
