import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart'; // 🔥 Import Joda Hua Hai
import 'auth_screen.dart'; 

class ResellerDashboardScreen extends StatefulWidget {
  final String resellerUsername;
  const ResellerDashboardScreen({Key? key, required this.resellerUsername}) : super(key: key);

  @override
  State<ResellerDashboardScreen> createState() => _ResellerDashboardScreenState();
}

class _ResellerDashboardScreenState extends State<ResellerDashboardScreen> {
  final _detailsController = TextEditingController();
  final _keyController = TextEditingController();
  
  String _generatedOrderId = "";
  bool _isLoading = false;
  bool _isOrderLive = false;
  List<dynamic> myOrderHistory = [];

  final String backendUrl = "https://nx-pop-shield-api.helenwick047.workers.dev/";

  @override
  void initState() {
    super.initState();
    _generateRandomOrderId();
    _fetchMyOrders();
  }

  void _generateRandomOrderId() {
    final random = Random();
    int nextId = random.nextInt(90000) + 10000; 
    setState(() {
      _generatedOrderId = "ORD-$nextId";
    });
  }

  Future<void> _fetchMyOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/reseller/orders?username=${widget.resellerUsername}'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          myOrderHistory = data['orders'] ?? [];
        });
      }
    } catch (e) {
      // Background fail silently
    }
  }

  Future<void> _postNewOrder() async {
    if (_detailsController.text.isEmpty || _keyController.text.isEmpty) {
      _showSnackBar("Please type order details and enter a valid Key!", Colors.red);
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/order/create'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "orderId": _generatedOrderId,
          "reseller": widget.resellerUsername,
          "orderDetails": _detailsController.text.trim(),
          "secretKey": _keyController.text.trim(), 
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar("🚀 Order is now LIVE inside market!", Colors.green);
        setState(() {
          _isOrderLive = true;
          _keyController.clear();
          _detailsController.clear();
        });
        _generateRandomOrderId(); 
        _fetchMyOrders(); 
      } else {
        _showSnackBar(data['message'] ?? 'Invalid Order Key!', Colors.red);
      }
    } catch (e) {
      _showSnackBar("Network Error: Unable to post order", Colors.red);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _stopLiveOrder(String orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/order/stop'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"orderId": orderId, "reseller": widget.resellerUsername}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar("🛑 Order Stopped! Watermarks removed from Sellers.", Colors.amber);
        _fetchMyOrders();
      }
    } catch (e) {
      _showSnackBar("Failed to stop order online", Colors.red);
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
        title: Text('📋 RESELLER PANEL (@${widget.resellerUsername})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout Account',
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Custom Telegram-Style Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🔒 Auto Generated Order ID:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text(_generatedOrderId, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _detailsController,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type order details manually here...\nExample:\nTarget Character ID: 51234889\nRate: ₹3.5/K Fast Send!\nSend Video Proofs on @my_username',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amber), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _keyController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Enter Secret Activation Key',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.vpn_key, color: Colors.amber),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amber), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _postNewOrder,
                  child: const Text('POST LIVE ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 35),
                const Text('⚡ Active / Past Orders History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 15),
                myOrderHistory.isEmpty 
                  ? const Text('No orders created yet.', style: TextStyle(color: Colors.grey))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: myOrderHistory.length,
                      itemBuilder: (context, index) {
                        final order = myOrderHistory[index];
                        bool isActive = order['status'] == 'Active';
                        return Card(
                          color: Colors.grey[950],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isActive ? Colors.green.withOpacity(0.5) : Colors.grey[800]!),
                          ),
                          margin: const EdgeInsets.only(bottom:14),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${order['orderId']}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                                    Text(
                                      isActive ? '🔴 LIVE' : '🛑 STOPPED',
                                      style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.grey, height: 20),
                                Text(order['orderDetails'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                                if (isActive) ...[
                                  const SizedBox(height: 15),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(40)),
                                    onPressed: () => _stopLiveOrder(order['orderId']),
                                    icon: const Icon(Icons.stop_circle, size: 18),
                                    label: const Text('STOP ORDER (Remove Watermarks)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  )
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    )
              ],
            ),
          ),
    );
  }
}