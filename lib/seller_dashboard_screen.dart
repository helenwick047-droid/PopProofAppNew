import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart'; 

class SellerDashboardScreen extends StatefulWidget {
  final String sellerUsername;
  const SellerDashboardScreen({Key? key, required this.sellerUsername}) : super(key: key);

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final _searchController = TextEditingController();
  List<dynamic> allLiveOrders = [];
  List<dynamic> displayedOrders = [];
  bool _isLoading = false;

  final String backendUrl = "https://nx-pop-shield-api.helenwick047.workers.dev";

  @override
  void initState() {
    super.initState();
    _fetchLiveMarketplace();
  }

  Future<void> _fetchLiveMarketplace() async {
    setState(() { _isLoading = true; });
    try {
      final response = await http.get(Uri.parse('$backendUrl/api/market/live-orders'));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          if (data is List) {
            allLiveOrders = data;
          } else if (data is Map && data['orders'] != null) {
            allLiveOrders = data['orders'];
          } else {
            allLiveOrders = data['orders'] ?? [];
          }
          displayedOrders = allLiveOrders;
        });
      }
    } catch (e) {
      _showSnackBar("Market refresh failed! Internet check karein.", Colors.red);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _filterOrders(String query) {
    if (query.isEmpty) {
      setState(() {
        displayedOrders = allLiveOrders;
      });
      return;
    }

    setState(() {
      displayedOrders = allLiveOrders
          .where((order) => order['orderId'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // 🔥 CRYSTAL CLEAR WATERMARK FIX
  void _startPopDeal(String orderId) async {
    try {
      final bool checkPermission = await FlutterOverlayWindow.isPermissionGranted();
      
      if (!checkPermission) {
        _showSnackBar("⚠️ Please allow 'Display over other apps' permission!", Colors.amber);
        await FlutterOverlayWindow.requestPermission();
        return; 
      }

      _showSnackBar("🛡️ Activating Secure Overlay for $orderId...", Colors.green);
      final bool? isActive = await FlutterOverlayWindow.isActive();
      
      if (isActive == false) {
        // 1. Overlay ko pehle native screen par successfully draw hone do
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true, 
          overlayTitle: "POP-PROOF LIVE",
          overlayContent: "Security Engine Running",
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPublic,
          height: 350,
          width: 750,
        );

        // 2. 🔥 CRITICAL TIMING FIX: 200ms ka gap diya taaki data pipeline crash na ho
        await Future.delayed(const Duration(milliseconds: 200));

        // 3. Ab target window ke andar safely order information share karo
        await FlutterOverlayWindow.shareData({
          "orderId": orderId,
          "sellerUsername": widget.sellerUsername,
        });
        
        _showSnackBar("✅ Watermark Active! Now open BGMI & start recording.", Colors.amber);
      } else {
        _showSnackBar("⚠️ An overlay is already running! Stop it first.", Colors.amber);
      }
    } catch (e) {
      _showSnackBar("Overlay Permission Error! Enable 'Draw over other apps' in Settings.", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('🔥 MARKETPLACE (@${widget.sellerUsername})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
        backgroundColor: Colors.grey[950],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amber),
            onPressed: _fetchLiveMarketplace,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout Session',
            onPressed: () async {
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear(); 
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterOrders,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by Unique Order ID (e.g. ORD-12345)...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.amber),
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amber), borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('🔴 Ongoing Live Orders Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : displayedOrders.isEmpty
                    ? const Center(child: Text('No matching live orders found.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: displayedOrders.length,
                        itemBuilder: (context, index) {
                          final order = displayedOrders[index];
                          return Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(6)),
                                        child: Text(
                                          '${order['orderId']}',
                                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        'By: @${order['reseller']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.grey, height: 24),
                                  Text(
                                    order['orderDetails'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                      minimumSize: const Size.fromHeight(42),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _startPopDeal(order['orderId']),
                                    icon: const Icon(Icons.send_rounded, size: 18),
                                    label: const Text('SEND POP', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
