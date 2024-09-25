import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  bool _isMapCreated = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.locationWhenInUse.request();
    print("Permission status: $status");
    if (status.isGranted) {
      setState(() {
        // Permissions granted, rebuild the widget to show the map.
      });
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapCreated = true;
    print("Map created successfully");
  }

  @override
  void dispose() {
    if (_isMapCreated) {
      _mapController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: _isMapCreated
          ? GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(
          target: LatLng(23.0225, 72.5714),
          zoom: 12,
        ),
        myLocationEnabled: true,
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
