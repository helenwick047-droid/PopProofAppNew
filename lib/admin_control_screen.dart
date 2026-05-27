import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart'; // Copy to Clipboard ke liye zaroori hai

class AdminControlScreen extends StatefulWidget {
  const AdminControlScreen({Key? key}) : super(key: key);

  @override
  State<AdminControlScreen> createState() => _AdminControlScreenState();
}

class _AdminControlScreenState extends State<AdminControlScreen> {
  List<dynamic> pendingResellers = [];
  bool _isLoading = false;
  
  // 🔥 NESTED NEW CONFIGURATION (Bina purane data ko chhede)
  final TextEditingController _keyInputController = TextEditingController();
  bool _isGeneratingKey = false;
  String _generatedKeyDisplay = "";

  final String backendUrl = "https://nx-pop-shield-api.helenwick047.workers.dev/";
  
  final Map<String, String> adminHeaders = {
    "Content-Type": "application/json",
    "Admin-Secret-Key": "MASTER_SECRET_LAUNCH_KEY_2026" 
  };

  @override
  void initState() {
    super.initState();
    _fetchPendingResellers();
  }

  Future<void> _fetchPendingResellers() async {
    setState(() { _isLoading = true; });
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/admin/pending-resellers'),
        headers: adminHeaders,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          pendingResellers = data['resellers'] ?? [];
        });
      } else {
        _showSnackBar(data['message'] ?? 'Failed to load list', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Network Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _updateStatus(String username, String action) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/admin/verify-reseller'),
        headers: adminHeaders,
        body: jsonEncode({
          "username": username,
          "action": action,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar('Reseller $username ${action == 'approve' ? 'APPROVED' : 'DISAPPROVED'}!', Colors.green);
        _fetchPendingResellers();
      } else {
        _showSnackBar(data['message'] ?? 'Action failed', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error performing action', Colors.red);
    }
  }

  // 🔥 NEW SAFE FUNCTION: MASTER PANEL SE KEY GENERATE KARNE KE LIYE
  Future<void> _generateSecretKey() async {
    final String keyText = _keyInputController.text.trim();
    if (keyText.isEmpty) {
      _showSnackBar('Please enter a key name/code!', Colors.orange);
      return;
    }

    setState(() { _isGeneratingKey = true; });
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/admin/generate-key'),
        headers: adminHeaders,
        body: jsonEncode({
          "secretKey": keyText
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _generatedKeyDisplay = keyText;
        });
        _keyInputController.clear();
        _showSnackBar('Activation Key Locked in DB successfully!', Colors.green);
      } else {
        _showSnackBar(data['message'] ?? 'Failed to generate key', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Server insertion failed', Colors.red);
    } finally {
      setState(() { _isGeneratingKey = false; });
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background fix
      appBar: AppBar(
        title: const Text('👑 MASTER CONTROL PANEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber)),
        backgroundColor: Colors.grey[950],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amber),
            onPressed: _fetchPendingResellers,
          )
        ],
      ),
      // Bottom Navigation Window Frame use kiya hai taaki key setup niche chipka rahe stable state mein
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[950],
          border: const Border(top: BorderSide(color: Colors.amber, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🗝️ CREATE RESELLER ACTIVATION KEY",
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keyInputController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "e.g., POP_VIP_778X",
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.amber),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _isGeneratingKey
                    ? const CircularProgressIndicator(color: Colors.amber)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _generateSecretKey,
                        child: const Text("GENERATE", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
            if (_generatedKeyDisplay.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _generatedKeyDisplay));
                  _showSnackBar('Key copied to clipboard!', Colors.green);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green, width: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Active Key: $_generatedKeyDisplay", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      const Icon(Icons.copy, size: 16, color: Colors.green),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : pendingResellers.isEmpty
              ? const Center(child: Text('No pending resellers found.', style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingResellers.length,
                  itemBuilder: (context, index) {
                    final reseller = pendingResellers[index];
                    return Card(
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.amber, width: 0.5),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.alternate_email, color: Colors.amber, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '@${reseller['username']}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Channel: ${reseller['channelLink'] ?? 'Not Provided'}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const Divider(color: Colors.grey, height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    foregroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _updateStatus(reseller['username'], 'disapprove'),
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('DISAPPROVE'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _updateStatus(reseller['username'], 'approve'),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
