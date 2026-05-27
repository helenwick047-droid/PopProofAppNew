import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // 🔥 Import Joda Hua Hai

import 'admin_control_screen.dart';
import 'reseller_dashboard_screen.dart';
import 'seller_dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSeller = true;
  bool isLoginMode = false; // 🔥 Seller ko login mode switch karne ke liye variable safely added
  bool isLoading = false;
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _channelController = TextEditingController();

  final String backendUrl = "https://nx-pop-shield-api.helenwick047.workers.dev";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoLogin(); 
    });
  }

  Future<void> _checkAutoLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedUser = prefs.getString('saved_session_username');
    final String? savedRole = prefs.getString('saved_session_role');

    if (savedUser != null && savedRole != null && mounted) {
      if (savedRole == 'seller') {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => SellerDashboardScreen(sellerUsername: savedUser))
        );
      } else if (savedRole == 'reseller') {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => ResellerDashboardScreen(resellerUsername: savedUser))
        );
      }
    }
  }

  Future<void> _saveUserSession(String username, String role) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_session_username', username);
    await prefs.setString('saved_session_role', role);
  }

  void openAdminPanel() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController _adminKeyController = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("👑 Admin Verification", style: TextStyle(color: Colors.amber)),
          content: TextField(
            controller: _adminKeyController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Enter Master Secret Key",
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (_adminKeyController.text == "OWNER_POP_2026") {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Access Granted! Opening Admin Panel...")));
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const AdminControlScreen())
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wrong Secret Key!")));
                }
              },
              child: const Text("VERIFY", style: TextStyle(color: Colors.amber)),
            )
          ],
        );
      },
    );
  }

  void handleSignup() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields!")));
      return;
    }
    setState(() => isLoading = true);
    try {
      String finalUser = _usernameController.text.trim().replaceAll('@', '');
      var response = await http.post(
        Uri.parse("$backendUrl/api/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": finalUser,
          "password": _passwordController.text.trim(),
          "role": isSeller ? "seller" : "reseller",
          "channelLink": _channelController.text.trim()
        }),
      );

      var data = jsonDecode(response.body);
      if (response.statusCode == 200 || data["success"] == true) {
        if (isSeller) {
          await _saveUserSession(finalUser, 'seller');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seller Registered Successfully!")));
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => SellerDashboardScreen(sellerUsername: finalUser))
            );
          }
        } else {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Colors.grey[900],
                title: const Text("💡 Account Pending Approval", style: TextStyle(color: Colors.amber)),
                content: const Text("To approve your reseller account, please contact the owner with your registered username.\n\nOwner Telegram: @SoulReaper404", style: TextStyle(color: Colors.white)),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: Colors.amber)))],
              ),
            );
          }
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data["message"] ?? "Error occurred")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Network Connection Error!")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill credentials!")));
      return;
    }
    setState(() => isLoading = true);
    try {
      String finalUser = _usernameController.text.trim().replaceAll('@', '');
      var response = await http.post(
        Uri.parse("$backendUrl/api/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": finalUser,
          "password": _passwordController.text.trim()
        }),
      );

      var data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        String userRole = data["role"] ?? (isSeller ? 'seller' : 'reseller');
        await _saveUserSession(finalUser, userRole);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Successful!")));
          if (userRole == 'seller') {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => SellerDashboardScreen(sellerUsername: finalUser))
            );
          } else {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => ResellerDashboardScreen(resellerUsername: finalUser))
            );
          }
        }
      } else if (response.statusCode == 403) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text("🔒 Approval Pending", style: TextStyle(color: Colors.amber)),
              content: const Text("Your account is not approved yet.\n\nContact Telegram: @SoulReaper404", style: TextStyle(color: Colors.white)),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: Colors.amber)))],
            ),
          );
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data["message"] ?? "Login Failed")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Server Connection Failed!")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Column(
              children: [
                GestureDetector(
                  onLongPress: openAdminPanel, 
                  child: Column(
                    children: [
                      const Icon(Icons.shield, color: Colors.amber, size: 60),
                      const SizedBox(height: 10),
                      const Text("POP-PROOF SECURITY", style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() { isSeller = true; isLoginMode = false; }), // Seller tab toggles default to Register
                      child: Text("I AM A SELLER", style: TextStyle(color: isSeller ? Colors.amber : Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() { isSeller = false; isLoginMode = true; }), // Reseller tab toggles default to Login
                      child: Text("I AM A RESELLER", style: TextStyle(color: !isSeller ? Colors.amber : Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(color: Colors.amber, thickness: 2),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Telegram Username (Without @)", labelStyle: TextStyle(color: Colors.grey), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber))),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Password", labelStyle: TextStyle(color: Colors.grey), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber))),
                ),
                if (!isSeller && !isLoginMode) ...[ // Shows link setup only when a new reseller is trying to submit form
                  const SizedBox(height: 15),
                  TextField(
                    controller: _channelController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Telegram Channel Link", labelStyle: TextStyle(color: Colors.grey), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber))),
                  ),
                ],
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 50)),
                  onPressed: isLoginMode ? handleLogin : handleSignup,
                  child: Text(
                    isSeller 
                      ? (isLoginMode ? "LOG IN TO MY ACCOUNT" : "REGISTER & LOGIN")
                      : (isLoginMode ? "LOG IN TO MY ACCOUNT" : "SUBMIT FOR APPROVAL"), 
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(height: 15),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.amber), minimumSize: const Size(double.infinity, 50)),
                  onPressed: () {
                    setState(() {
                      isLoginMode = !isLoginMode; // Safely toggle modes
                    });
                  },
                  child: Text(
                    isLoginMode ? "CREATE A NEW ACCOUNT" : "LOG IN TO EXISTING ACCOUNT", 
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)
                  ),
                )
              ],
            ),
          ),
    );
  }
}
