import 'package:flutter/material.dart';
import 'package:frontend/core/app/services/location/location_manager.dart';
import 'package:frontend/feature/safe_model/ui/map_screen.dart';

class SafeModePage extends StatefulWidget {
  const SafeModePage({super.key});

  @override
  _SafeModePageState createState() => _SafeModePageState();
}

class _SafeModePageState extends State<SafeModePage> {



  @override
  Widget build(BuildContext context) {
    return MapScreen();
    return Scaffold(
      appBar: AppBar(title: Text("Live Location Tracking")),
      body: Center(child: Text("Tracking...")),
    );
  }
}
