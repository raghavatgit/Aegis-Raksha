import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showEmergencyNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'emergency_channel_id',
        'Emergency Alerts Channel',
        channelDescription: 'High Priority System Notifications for Emergency Mesh',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        fullScreenIntent: true,
      );
      const NotificationDetails details = NotificationDetails(android: androidDetails);
      await _notificationsPlugin.show(0, title, body, details);
    } catch (_) {}
  }

  static Future<void> showLocalAlert({required String title, required String body}) =>
      showEmergencyNotification(title, body);

  static Future<void> playSirenSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/siren.mp3'));
    } catch (_) {}
  }

  static Future<void> stopSirenSound() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  static void dispose() {
    _audioPlayer.dispose();
  }
}
