import 'package:flutter/material.dart';

class OfflineDisasterMapScreen extends StatelessWidget {
  const OfflineDisasterMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: Text('Offline Tactical Mesh Map', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
