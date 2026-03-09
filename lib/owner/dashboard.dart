import 'package:flutter/material.dart';
import '../main.dart';
class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Admin"), backgroundColor: const Color(0xFF5F85DB) ,leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false),
      ),),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Icon(Icons.business_center, size: 80, color: Color(0xFF5F85DB)),
        SizedBox(height: 20),
        Text("Selamat Datang, Owner!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ])),
    );
  }
}