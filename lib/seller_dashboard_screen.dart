import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:system_alert_window/system_alert_window.dart'; // 🔥 Import Changed
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
      setState(() { displayedOrders = allLiveOrders; });
      return;
    }
    setState(() {
      displayedOrders = allLiveOrders
          .where((order) => order['orderId'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _startPopDeal(String orderId) async {
    try {
      // Modern Runtime permission check layer
      await SystemAlertWindow.requestPermissions(prefMode: SystemWindowPrefMode.OVERLAY);
      
      _showSnackBar("🛡️ Activating Secure Overlay for $orderId...", Colors.green);

      SystemWindowHeader header = SystemWindowHeader(
        title: SystemWindowText(text: "POP-PROOF LIVE", fontSize: 14, textColor: Colors.black, fontWeight: FontWeight.BOLD),
        subTitle: SystemWindowText(text: "Security Engine Running", fontSize: 12, textColor: Colors.black45),
        backgroundColor: Colors.amber,
      );

      SystemWindowBody body = SystemWindowBody(
        rows: [
          EachRow(
            columns: [
              EachColumn(
                text: SystemWindowText(text: "ORDER: $orderId\nSELLER: @${widget.sellerUsername}", fontSize: 14, textColor: Colors.black80, fontWeight: FontWeight.BOLD),
              ),
            ],
            gravity: ContentGravity.CENTER,
          ),
        ],
        backgroundColor: Colors.white,
      );

      // System configurations safe call bypasses native v1 blockages completely
      await SystemAlertWindow.showSystemWindow(
        height: 180,
        width: 360,
        header: header,
        body: body,
        gravity: SystemWindowGravity.CENTER,
        prefMode: SystemWindowPrefMode.OVERLAY,
      );

      // Cache data locally for secure reference
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_live_order', orderId);
      await prefs.setString('current_live_seller', widget.sellerUsername);

      _showSnackBar("✅ Watermark Active! Now open BGMI & start recording.", Colors.amber);
    } catch (e) {
      _showSnackBar("Overlay Setup Mismatch error!", Colors.red);
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
          IconButton(icon: const Icon(Icons.refresh, color: Colors.amber), onPressed: _fetchLiveMarketplace),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear(); 
              await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
              if (mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => AuthScreen()), (route) => false);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterOrders,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by Unique Order ID...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.amber),
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amber), borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
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
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${order['orderId']}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  Text(order['orderDetails'] ?? '', style: const TextStyle(color: Colors.white)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                                    onPressed: () => _startPopDeal(order['orderId']),
                                    child: const Text('SEND POP', style: TextStyle(fontWeight: FontWeight.bold)),
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
