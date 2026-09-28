import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_number(num_pages)
            canvas.Canvas.showPage(self)
        canvas.Canvas.save(self)

    def draw_page_number(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 9)
        self.setFillColor(colors.HexColor("#4A5568"))
        
        # Header (pages > 1)
        if self._pageNumber > 1:
            self.drawString(54, 750, "Raksha Emergency Mesh - 100 Presentation & Viva Q&A Guide")
            self.setStrokeColor(colors.HexColor("#CBD5E0"))
            self.setLineWidth(0.5)
            self.line(54, 742, 558, 742)

        # Footer
        footer_text = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(558, 36, footer_text)
        self.drawString(54, 36, "CONFIDENTIAL - Viva & Presentation Preparation")
        self.setStrokeColor(colors.HexColor("#CBD5E0"))
        self.setLineWidth(0.5)
        self.line(54, 48, 558, 48)
        
        self.restoreState()

def build_pdf():
    pdf_filename = r"c:\src\raksha_emergency_mesh\Raksha_Emergency_Mesh_100_QnA.pdf"
    doc = SimpleDocTemplate(
        pdf_filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=28,
        textColor=colors.HexColor("#9B2C2C"),
        alignment=1,
        spaceAfter=10
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor("#2D3748"),
        alignment=1,
        spaceAfter=20
    )

    meta_style = ParagraphStyle(
        'DocMeta',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        textColor=colors.HexColor("#4A5568"),
        alignment=1,
        spaceAfter=25
    )

    cat_style = ParagraphStyle(
        'CategoryHeader',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=18,
        textColor=colors.HexColor("#FFFFFF"),
        spaceBefore=0,
        spaceAfter=0,
        keepWithNext=True
    )

    q_style = ParagraphStyle(
        'QuestionText',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=10.5,
        leading=14,
        textColor=colors.HexColor("#1A202C"),
        spaceBefore=6,
        spaceAfter=3,
        keepWithNext=True
    )

    a_style = ParagraphStyle(
        'AnswerText',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=13.5,
        textColor=colors.HexColor("#2D3748"),
        spaceBefore=0,
        spaceAfter=8
    )

    story = []

    # Title & Header
    story.append(Paragraph("RAKSHA EMERGENCY MESH", title_style))
    story.append(Paragraph("100 Comprehensive Viva & Presentation Questions & Answers", subtitle_style))
    story.append(Paragraph("<b>Project:</b> Raksha Emergency Mesh (Offline SOS P2P Mesh Network)<br/><b>Tech Stack:</b> Flutter, Dart, flutter_nearby_connections, Hive NoSQL DB, Firebase Realtime DB, Geolocator<br/><b>Prepared For:</b> Academic Presentation & Viva Defense", meta_style))
    story.append(HRFlowable(width="100%", thickness=2, color=colors.HexColor("#9B2C2C"), spaceBefore=0, spaceAfter=15))

    qna_data = [
        # Category 1
        ("CATEGORY 1: Project Aim, Scope & Problem Statement", [
            ("Q1: What is the main aim of the 'Raksha Emergency Mesh' project?",
             "<b>Answer:</b> To provide a reliable, decentralized offline emergency communication network that allows users to send SOS alerts, live location data, and emergency messages during natural disasters or network blackouts without requiring cellular data or internet infrastructure."),

            ("Q2: Why is traditional communication inadequate during disasters?",
             "<b>Answer:</b> Cellular towers and internet backbones often suffer physical damage, severe network congestion, or power outages during earthquakes, floods, or major blackouts. Raksha solves this by forming an ad-hoc peer-to-peer (P2P) mesh network directly between nearby smartphones."),

            ("Q3: Who is the target audience for this application?",
             "<b>Answer:</b> Disaster survivors, emergency first responders, search-and-rescue teams, defense personnel, outdoor hikers, and citizens operating in zero-connectivity or remote regions."),

            ("Q4: What key features are currently implemented in Raksha Emergency Mesh?",
             "<b>Answer:</b> Offline SOS alert broadcasting, P2P mesh message relaying (multi-hop), local offline database storage using Hive, real-time GPS coordinate tagging, siren audio alert playback, local push notifications, and hybrid cloud synchronization via Firebase when internet resumes."),

            ("Q5: What is the core innovation of this project?",
             "<b>Answer:</b> Combining Bluetooth LE/Wi-Fi Direct P2P mesh networking with a TTL (Time-To-Live) multi-hop relay mechanism, fast local NoSQL storage, and automatic cloud back-sync once internet connectivity is restored."),

            ("Q6: How does multi-hop relaying work in emergency situations?",
             "<b>Answer:</b> If User A is trapped and out of reach of a relief tower but near User B, and User B is near User C who has internet, User A's SOS message 'hops' through User B to User C, reaching the central rescue cloud without User A needing direct internet."),

            ("Q7: What is the scope of this project implementation?",
             "<b>Answer:</b> Peer device discovery, local mesh networking, real-time GPS tagging, offline data persistence, audio-visual alarms, background notifications, and optional cloud sync."),

            ("Q8: Is this application online-only, offline-only, or hybrid?",
             "<b>Answer:</b> It is an <b>Offline-First Hybrid Application</b>. It operates 100% offline via local device mesh and automatically syncs data to the cloud whenever internet connectivity becomes available."),

            ("Q9: What happens when multiple SOS alerts are sent simultaneously?",
             "<b>Answer:</b> Every alert carries a unique UUID, timestamp, and sender ID. The Hive database stores them independently, and the mesh network broadcasts them across connected nodes using deduplication logs to prevent duplicates."),

            ("Q10: What real-world disaster scenarios can Raksha be deployed in?",
             "<b>Answer:</b> Earthquakes, floods, tsunamis, forest fires, stadium network overloads, underground metro tunnels, and remote mountain trekking.")
        ]),

        # Category 2
        ("CATEGORY 2: Flutter Framework & Dart Language Fundamentals", [
            ("Q11: What is Flutter and why was it chosen for this project?",
             "<b>Answer:</b> Flutter is Google's open-source UI toolkit for building natively compiled cross-platform apps (Android, iOS, Web, Desktop) from a single codebase using Dart. It was chosen for fast UI rendering, native hardware access, and cross-platform reach."),

            ("Q12: What programming language is used in Flutter and what are its advantages?",
             "<b>Answer:</b> <b>Dart</b>. Key advantages include Ahead-Of-Time (AOT) compilation for native machine code performance, Just-In-Time (JIT) compilation for rapid hot reload during development, strong typing, and built-in asynchronous programming primitives (Future/Stream)."),

            ("Q13: Why choose Flutter over React Native for an emergency mesh app?",
             "<b>Answer:</b> Flutter renders directly via the Impeller/Skia engine without a JS bridge, resulting in consistent 60/120 FPS performance, lower latency, predictable memory usage, and tighter native hardware binding required for Bluetooth sockets."),

            ("Q14: What is the difference between Stateful and Stateless Widgets in Flutter?",
             "<b>Answer:</b> <code>StatelessWidget</code> is immutable and does not change dynamically once built. <code>StatefulWidget</code> maintains mutable state that can rebuild the UI dynamically when <code>setState()</code> is called (e.g., live device list, active SOS alerts)."),

            ("Q15: What is 'WidgetsFlutterBinding.ensureInitialized()' used for in main.dart?",
             "<b>Answer:</b> It ensures that the Flutter engine's binary messenger and framework bindings are fully initialized before calling asynchronous native services like Hive database init or local notifications."),

            ("Q16: How does Flutter compile for Android and iOS?",
             "<b>Answer:</b> In production builds (<code>flutter build apk</code>), Flutter compiles Dart code directly into native ARM machine code binaries via AOT compilation, ensuring high performance without runtime interpreters."),

            ("Q17: What is Hot Reload and how does it speed up development?",
             "<b>Answer:</b> Hot Reload injects updated source code into the running Dart Virtual Machine (VM) in sub-second time without destroying the app's current state."),

            ("Q18: What is Material Design 3 and how is it configured in the app?",
             "<b>Answer:</b> Material 3 is Google's latest design system. In <code>main.dart</code>, <code>useMaterial3: true</code> is set with <code>ColorScheme.fromSeed(seedColor: Colors.red)</code> for high-visibility emergency red styling."),

            ("Q19: How are asynchronous operations handled in Dart?",
             "<b>Answer:</b> Using <code>Future</code> for single async results, <code>async/await</code> syntax, and <code>Stream</code> for continuous event-driven data flows (e.g., listening to incoming peer network connections)."),

            ("Q20: What is the purpose of analysis_options.yaml in this project?",
             "<b>Answer:</b> It defines static analysis and linting rules (<code>flutter_lints</code>) to maintain high code quality, enforce style guidelines, and catch potential bugs early.")
        ]),

        # Category 3
        ("CATEGORY 3: Peer-to-Peer Mesh Networking (flutter_nearby_connections)", [
            ("Q21: What package is used for Peer-to-Peer mesh networking?",
             "<b>Answer:</b> <code>flutter_nearby_connections</code> (Version <code>^1.1.2</code>), which wraps Android's Nearby Connections API and iOS Multipeer Connectivity framework."),

            ("Q22: What underlying protocols are used for device-to-device communication?",
             "<b>Answer:</b> A combination of <b>Wi-Fi Direct</b> (High bandwidth, medium range) and <b>Bluetooth Low Energy (BLE)</b> (Low power, discovery phase)."),

            ("Q23: What are Advertising and Discovery modes in P2P mesh networking?",
             "<b>Answer:</b> <b>Advertising Mode</b> broadcasts the device's presence to nearby phones; <b>Discovery Mode</b> scans the physical area for nearby advertising devices."),

            ("Q24: How does multi-hop mesh forwarding work in EmergencyAlert model?",
             "<b>Answer:</b> Each alert has a <code>ttlHops</code> (Time-To-Live) counter initialized to 5. When a node receives an alert, it decrements <code>ttlHops</code> by 1 and re-broadcasts it to nearby connected nodes if <code>ttlHops > 0</code>."),

            ("Q25: How do we prevent infinite loops and packet flooding in the mesh network?",
             "<b>Answer:</b> 1) Enforcing a maximum <code>ttlHops</code> limit (5 hops). 2) Maintaining a <code>relay_log</code> in Hive to store processed <code>alertId</code>s so already forwarded alerts are ignored."),

            ("Q26: What is the data payload format sent across nearby devices?",
             "<b>Answer:</b> JSON strings containing <code>alert_id</code>, <code>sender_id</code>, <code>alert_type</code>, <code>severity</code>, <code>location</code> (lat/lng), <code>description</code>, <code>timestamp</code>, and <code>ttl_hops</code>."),

            ("Q27: What is the typical physical range of Bluetooth/Wi-Fi Direct P2P?",
             "<b>Answer:</b> Bluetooth LE: 10–30 meters; Wi-Fi Direct: 50–100 meters outdoors without physical line-of-sight obstructions."),

            ("Q28: How are device connection state changes monitored?",
             "<b>Answer:</b> Via <code>StreamSubscription</code> listening to <code>nearbyService.stateChangedSubscription</code> which emits device status updates (<code>connected</code>, <code>connecting</code>, <code>notConnected</code>)."),

            ("Q29: Can two phones on different OS (Android & iOS) communicate via this mesh?",
             "<b>Answer:</b> Yes, Bluetooth LE discovery and P2P sockets allow cross-platform data exchange when protocol bridges are enabled."),

            ("Q30: What happens if a connected peer node moves out of range?",
             "<b>Answer:</b> The stream triggers a state change to <code>notConnected</code>, updates the local UI device list, and automatically attempts rediscovery/reconnection.")
        ]),

        # Category 4
        ("CATEGORY 4: Offline Storage & Local NoSQL Database (Hive)", [
            ("Q31: What database is used for offline storage in this project?",
             "<b>Answer:</b> <b>Hive</b> (<code>hive: ^2.2.3</code> and <code>hive_flutter: ^1.1.0</code>), a lightweight, ultra-fast key-value NoSQL database written in pure Dart."),

            ("Q32: Why use Hive instead of SQLite (sqflite) or shared_preferences?",
             "<b>Answer:</b> Hive is significantly faster than SQLite (no native C bridges), requires zero SQL boilerplate setup, supports complex JSON maps natively, and has a smaller memory footprint."),

            ("Q33: What are 'Boxes' in Hive?",
             "<b>Answer:</b> Hive stores data in 'Boxes' (similar to tables or collections in traditional databases)."),

            ("Q34: Which Hive Boxes are initialized in main.dart?",
             "<b>Answer:</b> Three boxes: <code>'alerts'</code> (stores emergency SOS alerts), <code>'relay_log'</code> (stores forwarded alert IDs), and <code>'chat_messages'</code> (stores local mesh chat messages)."),

            ("Q35: How is Hive initialized when the application launches?",
             "<b>Answer:</b> <code>await Hive.initFlutter();</code> followed by <code>await Hive.openBox(...)</code> inside <code>main()</code> before <code>runApp()</code>."),

            ("Q36: How does Hive persist data across app restarts or device reboots?",
             "<b>Answer:</b> Hive writes binary key-value pairs directly to the device's local application storage directory disk files (<code>.hive</code> files)."),

            ("Q37: How are EmergencyAlert objects serialized and stored in Hive?",
             "<b>Answer:</b> Using <code>alert.toJson()</code> to convert the object into a JSON Map before calling <code>box.put(alertId, jsonMap)</code>."),

            ("Q38: How are saved alerts retrieved from Hive on startup?",
             "<b>Answer:</b> In <code>_loadSavedAlerts()</code>, the app iterates over <code>box.keys</code>, extracts stored maps, converts them via <code>EmergencyAlert.fromJson()</code>, and sets widget state."),

            ("Q39: What is the purpose of the 'firebase_sync_log' box?",
             "<b>Answer:</b> It tracks which <code>alertId</code>s have already been synced to Cloud Firebase so duplicate uploads are avoided when internet reconnects."),

            ("Q40: Is Hive data encrypted in this version?",
             "<b>Answer:</b> Currently stored unencrypted for maximum speed, but Hive supports AES-256 encryption via <code>HiveAESKey</code> for sensitive field encryption in production.")
        ]),

        # Category 5
        ("CATEGORY 5: Backend & Cloud Synchronization (Firebase Realtime Database)", [
            ("Q41: What cloud backend technology is used in this project?",
             "<b>Answer:</b> <b>Firebase Realtime Database</b> via <code>firebase_core</code> (<code>^2.13.0</code>) and <code>firebase_database</code> (<code>^10.0.5</code>)."),

            ("Q42: Why use Firebase Realtime Database instead of Cloud Firestore or REST APIs?",
             "<b>Answer:</b> Firebase Realtime Database uses low-latency WebSockets, handles rapid real-time updates seamlessly, and supports offline caching natively."),

            ("Q43: What is the role of FirebaseSyncService in lib/services/firebase_sync_service.dart?",
             "<b>Answer:</b> It handles background initialization of Firebase and syncs local offline Hive alerts to the cloud (<code>emergency_alerts/${alert.alertId}</code>) once internet connectivity is restored."),

            ("Q44: How does syncOfflineAlerts() determine which alerts to upload?",
             "<b>Answer:</b> It iterates through local <code>'alerts'</code> in Hive, checks if the <code>alertId</code> exists in <code>'firebase_sync_log'</code>, and uploads only unsynced alerts."),

            ("Q45: What happens if the app is launched completely offline with no internet?",
             "<b>Answer:</b> <code>FirebaseSyncService.initFirebase()</code> catches the network exception gracefully, logs a notice, and the app operates 100% in local mesh mode without crashing."),

            ("Q46: How does cloud synchronization benefit rescue teams outside the local mesh zone?",
             "<b>Answer:</b> Once any single node in the mesh touches an internet connection (e.g., emergency helicopter or satellite link), all collected alerts are uploaded to Firebase, giving centralized command centers live visibility."),

            ("Q47: What format is used when writing data to Firebase Realtime Database?",
             "<b>Answer:</b> JSON tree format populated via <code>alert.toJson()</code>."),

            ("Q48: How is duplicate cloud sync prevented if multiple nodes sync the same alert?",
             "<b>Answer:</b> Firebase nodes are keyed by unique <code>alertId</code> (<code>emergency_alerts/{alertId}</code>). Overwriting or setting the same key is idempotent."),

            ("Q49: Can rescue teams push status updates back to victim devices via Firebase?",
             "<b>Answer:</b> Yes, Firebase streams allow real-time listeners (<code>onValue</code>) to push acknowledgment or status updates (e.g., 'Rescue team en route') back down to connected nodes."),

            ("Q50: What security rules should be configured in Firebase Realtime Database?",
             "<b>Answer:</b> Read/Write rules enforcing authenticated app signatures, schema validation on <code>alert_id</code>, <code>severity</code>, <code>location</code>, and rate limiting.")
        ]),

        # Category 6
        ("CATEGORY 6: Geolocation & Real-Time Tracking (geolocator)", [
            ("Q51: What package is used to get the user's location?",
             "<b>Answer:</b> <code>geolocator</code> (Version <code>^13.0.2</code>)."),

            ("Q52: What location parameters are included in an EmergencyAlert?",
             "<b>Answer:</b> Latitude (<code>lat</code>) and Longitude (<code>lng</code>) doubles stored inside the <code>location</code> Map."),

            ("Q53: What permissions are required for location tracking on mobile devices?",
             "<b>Answer:</b> <code>Permission.location</code> / <code>Permission.locationWhenInUse</code> in Android/iOS manifests and checked via <code>permission_handler</code>."),

            ("Q54: What happens if GPS location services are disabled on the user's phone?",
             "<b>Answer:</b> The app prompts the user to enable Location Services or defaults location coordinates to <code>(0.0, 0.0)</code> while allowing text/audio alert transmission."),

            ("Q55: Does geolocator work offline without cellular data or internet?",
             "<b>Answer:</b> <b>Yes!</b> GPS hardware inside smartphones connects directly to orbiting satellite constellations (GPS, GLONASS, Galileo) and does not require internet access."),

            ("Q56: How is location accuracy configured in Flutter?",
             "<b>Answer:</b> Using <code>Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)</code> to balance pinpoint location accuracy with battery consumption."),

            ("Q57: Why is exact location tagging critical in disaster emergency management?",
             "<b>Answer:</b> Rescue personnel need precise coordinates to navigate directly to victims trapped in rubble, floods, or dense forests."),

            ("Q58: Can the app show victims on an offline map?",
             "<b>Answer:</b> In future enhancements, offline vector maps (like <code>flutter_map</code> with cached OpenStreetMap tiles) can render lat/lng coordinates without network access."),

            ("Q59: How does location updating affect device battery life during emergencies?",
             "<b>Answer:</b> Continuous GPS polling drains battery. Raksha fetches location on-demand when sending an SOS or periodically every 5-10 minutes."),

            ("Q60: How are invalid or null coordinates handled in EmergencyAlert.fromJson?",
             "<b>Answer:</b> Using Dart null-safety fallback: <code>(json['location']?['lat'] as num?)?.toDouble() ?? 0.0</code>.")
        ]),

        # Category 7
        ("CATEGORY 7: Alerting, Audio Alarms & Notifications", [
            ("Q61: What package handles system notifications in the background?",
             "<b>Answer:</b> <code>flutter_local_notifications</code> (Version <code>^17.0.0</code>)."),

            ("Q62: What package is used for emergency siren audio playback?",
             "<b>Answer:</b> <code>audioplayers</code> (Version <code>^6.1.0</code>)."),

            ("Q63: Why play audio alarms and send notifications when an alert arrives?",
             "<b>Answer:</b> Immediate auditory and visual cues ensure users nearby are alerted instantly even if their phone screen is locked or in their pocket."),

            ("Q64: How is visual flashing/blinking implemented in the UI during an alert?",
             "<b>Answer:</b> Using an <code>AnimationController</code> with <code>duration: Duration(milliseconds: 500)</code> configured with <code>.repeat(reverse: true)</code> for high-visibility red flashing headers."),

            ("Q65: What fields are present in the EmergencyAlert model?",
             "<b>Answer:</b> <code>alertId</code>, <code>senderId</code>, <code>alertType</code> (e.g., Medical, Fire, SOS, Flood), <code>severity</code> (Critical, High, Medium, Low), <code>location</code>, <code>description</code>, <code>timestamp</code>, and <code>ttlHops</code>."),

            ("Q66: How is a unique alertId generated for every SOS?",
             "<b>Answer:</b> Using <code>const Uuid().v4()</code>, generating a universally unique 128-bit string identifier (e.g., <code>f47ac10b-58cc-4372-a567-0e02b2c3d479</code>)."),

            ("Q67: What severity levels are supported in the application?",
             "<b>Answer:</b> <b>Critical</b> (Immediate life threat), <b>High</b> (Urgent assistance), <b>Medium</b> (General alert), and <b>Info</b> (Status update)."),

            ("Q68: Can users exchange text messages over the mesh network?",
             "<b>Answer:</b> Yes, <code>chatMessages</code> are stored in Hive (<code>'chat_messages'</code>) and relayed across connected nodes alongside emergency SOS alerts."),

            ("Q69: How are notifications configured for Android?",
             "<b>Answer:</b> In <code>main()</code>, <code>AndroidInitializationSettings('@mipmap/ic_launcher')</code> sets the app launcher icon as the notification icon."),

            ("Q70: What happens when a user taps a received local notification?",
             "<b>Answer:</b> The notification callback opens the app directly to the SOS Alert Detail screen showing sender details and GPS coordinates.")
        ]),

        # Category 8
        ("CATEGORY 8: Hardware Permissions, Security & Privacy", [
            ("Q71: What package manages device hardware permissions?",
             "<b>Answer:</b> <code>permission_handler</code> (Version <code>^11.3.0</code>)."),

            ("Q72: What permissions must be granted by the user on Android 12+?",
             "<b>Answer:</b> <code>BLUETOOTH_SCAN</code>, <code>BLUETOOTH_ADVERTISE</code>, <code>BLUETOOTH_CONNECT</code>, <code>ACCESS_FINE_LOCATION</code>, and <code>NEARBY_WIFI_DEVICES</code>."),

            ("Q73: What happens if a user denies location or Bluetooth permissions?",
             "<b>Answer:</b> The app displays an in-app permission banner explaining why permissions are required and provides a button to open App Settings."),

            ("Q74: How are sender devices uniquely identified without requiring user signup/login?",
             "<b>Answer:</b> A random UUID is generated on first launch and stored locally in Hive as the device <code>senderId</code>."),

            ("Q75: Is user privacy protected when broadcasting alerts over P2P mesh?",
             "<b>Answer:</b> Yes, alerts only contain necessary emergency metadata (<code>senderId</code>, <code>alertType</code>, <code>location</code>, <code>description</code>) without exposing private personal credentials."),

            ("Q76: How can false/tampered emergency alerts be prevented in a P2P mesh?",
             "<b>Answer:</b> Using cryptographic digital signatures (e.g., Public/Private key pairs) where each node verifies the origin signature before forwarding."),

            ("Q77: What security vulnerabilities exist in open mesh networks?",
             "<b>Answer:</b> Denial-of-Service (DoS) spamming, eavesdropping on unencrypted packets, and relaying fake SOS locations."),

            ("Q78: How does Raksha mitigate mesh spamming/flooding?",
             "<b>Answer:</b> By enforcing <code>ttlHops</code> limits, maintaining <code>relay_log</code> deduplication boxes, and rate-limiting outgoing broadcasts."),

            ("Q79: What Android permissions are defined in AndroidManifest.xml?",
             "<b>Answer:</b> <code>INTERNET</code>, <code>ACCESS_FINE_LOCATION</code>, <code>ACCESS_COARSE_LOCATION</code>, <code>BLUETOOTH</code>, <code>BLUETOOTH_ADMIN</code>, <code>BLUETOOTH_SCAN</code>, <code>BLUETOOTH_CONNECT</code>, <code>BLUETOOTH_ADVERTISE</code>, <code>CHANGE_WIFI_STATE</code>, <code>ACCESS_WIFI_STATE</code>."),

            ("Q80: Is special permission required to run an app in Airplane Mode, and how does mesh networking function in Airplane Mode?",
             "<b>Answer:</b> <b>No!</b> No special permission is required to run apps in Airplane Mode. Airplane Mode disables cellular data by default, but users can manually re-enable Bluetooth and Wi-Fi Direct in settings while remaining in Airplane Mode. Raksha uses standard Bluetooth (<code>BLUETOOTH_SCAN</code>, <code>BLUETOOTH_CONNECT</code>) and <code>ACCESS_FINE_LOCATION</code> permissions to run the offline P2P mesh.")
        ]),

        # Category 9
        ("CATEGORY 9: Code Structure & Implementation Details", [
            ("Q81: What is the main entry point file of the application?",
             "<b>Answer:</b> <code>lib/main.dart</code>."),

            ("Q82: Where is the emergency alert data model defined?",
             "<b>Answer:</b> <code>lib/models/emergency_alert.dart</code>."),

            ("Q83: Where is the cloud synchronization logic implemented?",
             "<b>Answer:</b> <code>lib/services/firebase_sync_service.dart</code>."),

            ("Q84: What happens inside main() in lib/main.dart?",
             "<b>Answer:</b> 1) <code>WidgetsFlutterBinding.ensureInitialized()</code>, 2) <code>Hive.initFlutter()</code>, 3) Opening boxes (<code>alerts</code>, <code>relay_log</code>, <code>chat_messages</code>), 4) Init Notifications, 5) Init Firebase, 6) <code>runApp(MyApp())</code>."),

            ("Q85: How is JSON serialization implemented in EmergencyAlert class?",
             "<b>Answer:</b> Using <code>toJson()</code> returning <code>Map<String, dynamic></code> and <code>factory EmergencyAlert.fromJson(Map<String, dynamic> json)</code> factory constructor."),

            ("Q86: How is the release binary APK generated for Android?",
             "<b>Answer:</b> By running <code>flutter build apk --release</code>, generating the standalone APK executable <code>app-release.apk</code> (~53.8 MB)."),

            ("Q87: What theme color scheme is applied across the app?",
             "<b>Answer:</b> <code>ColorScheme.fromSeed(seedColor: Colors.red, primary: Colors.red[700])</code> for high-contrast emergency warning visuals."),

            ("Q88: How are animation controllers properly cleaned up in Flutter?",
             "<b>Answer:</b> Inside <code>dispose()</code>, calling <code>_blinkController.dispose()</code>, <code>_stateSubscription?.cancel()</code>, and <code>_audioPlayer.dispose()</code>."),

            ("Q89: How is multi-threading or async execution managed during mesh discovery?",
             "<b>Answer:</b> Dart single-threaded Event Loop handles async events via <code>StreamSubscription</code>s without blocking the main UI thread."),

            ("Q90: What configuration file defines package dependencies and assets?",
             "<b>Answer:</b> <code>pubspec.yaml</code>.")
        ]),

        # Category 10
        ("CATEGORY 10: Viva Defense, Evaluation & Future Roadmap", [
            ("Q91: What was the biggest technical challenge faced while building this project?",
             "<b>Answer:</b> Managing dynamic Android 12+ Bluetooth/Location permission changes and maintaining stable multi-peer P2P sockets without dropping connections."),

            ("Q92: How does your app compare to existing emergency apps like Bridgefy or Zello?",
             "<b>Answer:</b> Bridgefy is closed-source; Zello requires voice bandwidth. Raksha is lightweight, open-source, combines Hive storage with automatic Firebase cloud sync, and requires zero setup."),

            ("Q93: How will the system perform with 1,000 active nodes in a crowded area?",
             "<b>Answer:</b> Multi-hop TTL bounds (5 hops max) and Hive <code>relay_log</code> deduplication prevent network congestions and broadcast storms."),

            ("Q94: What is the current memory and storage footprint of the application?",
             "<b>Answer:</b> APK size is ~53.8 MB; RAM consumption is ~60–90 MB; local Hive storage per alert is under 1 KB."),

            ("Q95: Can this app be deployed on low-end Android smartphones?",
             "<b>Answer:</b> Yes, Flutter compiles down to native ARM binaries and Hive uses minimal RAM/CPU, making it suitable for budget smartphones."),

            ("Q96: How can battery consumption be minimized during prolonged disasters?",
             "<b>Answer:</b> Implementing dynamic duty-cycling (e.g., turning off Bluetooth scanning for 30 seconds every minute when idle)."),

            ("Q97: What hardware modules could be integrated in the future for longer range?",
             "<b>Answer:</b> <b>LoRa (Long Range) Radio Modules</b> (e.g., ESP32 LoRa SX1276) via Bluetooth/USB serial bridge to achieve 5–15 km long-distance mesh transmission."),

            ("Q98: What is the future roadmap for Raksha Emergency Mesh?",
             "<b>Answer:</b> 1) End-to-end AES-256 payload encryption, 2) Offline Map tile rendering, 3) Auto-SMS gateway fallback via cell tower edges, 4) Rescue drone node integration."),

            ("Q99: If an examiner asks 'Why did you build this?', what is your elevator pitch?",
             "<b>Answer:</b> 'In severe disasters, traditional cellular networks fail first. Raksha turns everyday smartphones into a self-healing emergency mesh network to route life-saving SOS alerts and location coordinates to safety, offline.'"),

            ("Q100: What is your final concluding summary of the project?",
             "<b>Answer:</b> Raksha Emergency Mesh proves that cross-platform Flutter combined with P2P protocols, fast local Hive storage, and Firebase cloud sync provides a robust, life-saving communications infrastructure for emergency situations.")
        ])
    ]

    for cat_title, q_list in qna_data:
        # Category Banner Table
        header_para = Paragraph(cat_title, cat_style)
        header_table = Table([[header_para]], colWidths=[504])
        header_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#9B2C2C")),
            ('PADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('TOPPADDING', (0, 0), (-1, -1), 8),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ]))
        
        story.append(Spacer(1, 10))
        story.append(header_table)
        story.append(Spacer(1, 8))

        for q_text, a_text in q_list:
            item_elements = [
                Paragraph(q_text, q_style),
                Paragraph(a_text, a_style),
                Spacer(1, 2)
            ]
            story.append(KeepTogether(item_elements))

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF generated successfully: {pdf_filename}")

if __name__ == "__main__":
    build_pdf()
