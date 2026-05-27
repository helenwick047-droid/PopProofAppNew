import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class FloatingWatermarkWindow extends StatefulWidget {
  const FloatingWatermarkWindow({Key? key}) : super(key: key);

  @override
  State<FloatingWatermarkWindow> createState() => _FloatingWatermarkWindowState();
}

class _FloatingWatermarkWindowState extends State<FloatingWatermarkWindow> {
  String orderId = "Loading...";
  String sellerUsername = "Loading...";
  String liveTime = "00:00:00 PM";
  
  Timer? _clockTimer;
  Timer? _statusCheckTimer;
  StreamSubscription? _overlaySubscription;
  
  final String backendUrl = "https://nx-pop-shield-api.helenwick047.workers.dev"; 

  @override
  void initState() {
    super.initState();
    
    // 🔥 CRYSTAL CLEAR FIX: Widgets Binding Wrapper lagaya taaki background me UI crash na ho
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((data) {
        if (data != null && data is Map) {
          if (mounted) {
            setState(() {
              orderId = data['orderId']?.toString() ?? "N/A";
              sellerUsername = data['sellerUsername']?.toString() ?? "N/A";
            });
          }
        }
      });
    });

    _startSecureClock();
    _startRemoteControlListener();
  }

  void _startSecureClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)); 
      
      int rawHour = now.hour;
      int displayHour = rawHour > 12 ? rawHour - 12 : (rawHour == 0 ? 12 : rawHour);
      
      String hour = '$displayHour'.padLeft(2, '0');
      String minute = '${now.minute}'.padLeft(2, '0');
      String second = '${now.second}'.padLeft(2, '0');
      String ampm = rawHour >= 12 ? 'PM' : 'AM';

      if (mounted) {
        setState(() {
          liveTime = "$hour:$minute:$second $ampm";
        });
      }
    });
  }

  void _startRemoteControlListener() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (orderId == "Loading..." || orderId == "N/A") return;

      try {
        final response = await http.get(Uri.parse('$backendUrl/api/market/live-orders'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          List<dynamic> orders = [];
          if (data is List) {
            orders = data;
          } else if (data is Map && data['orders'] != null) {
            orders = data['orders'];
          }

          bool stillActive = orders.any((o) => o['orderId']?.toString() == orderId && o['status'] == 'Active');
          
          if (!stillActive) {
            _closeWatermarkEngine();
          }
        }
      } catch (e) {
        // Fail silently
      }
    });
  }

  void _closeWatermarkEngine() async {
    _clockTimer?.cancel();
    _statusCheckTimer?.cancel();
    _overlaySubscription?.cancel();
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _statusCheckTimer?.cancel();
    _overlaySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, 
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6), 
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tag, color: Colors.amber, size: 14),
                  const SizedBox(width: 5),
                  Text('ORDER: $orderId', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, color: Colors.white70, size: 14),
                  const SizedBox(width: 5),
                  Text('SELLER: @$sellerUsername', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, color: Colors.amber, size: 14),
                  const SizedBox(width: 5),
                  Text('TIME: $liveTime', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
