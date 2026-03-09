// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'list_produk.dart';
import '../main.dart';
import 'batch_produk.dart';
import 'category.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const ListProdukWrapper(),
    const BatchProdukPage(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) { setState(() { _currentIndex = index; }); },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5F85DB),
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Produk'),
          BottomNavigationBarItem(icon: Icon(Icons.layers_outlined), activeIcon: Icon(Icons.layers), label: 'Batch Stok'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F85DB)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF0F3F8), shape: BoxShape.circle),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.notifications_none, color: Colors.grey.shade700, size: 24),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Halo, Admin! 👋", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey.shade800, height: 1.2)),
              const SizedBox(height: 6),
              Text("Berikut ringkasan performa toko Anda hari ini.", style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.4)),
              const SizedBox(height: 30),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                // PERBAIKAN 1: Mengubah rasio menjadi 0.85 (Kartu lebih tinggi) agar teks muat
                childAspectRatio: 0.85, 
                children: [
                  _buildSummaryCard("Total Produk", "120", const Color(0xFF5F85DB), Icons.inventory_2_rounded, const Color(0xFFEBF2FF)),
                  _buildSummaryCard("Transaksi", "15", const Color(0xFF00B894), Icons.shopping_bag_outlined, const Color(0xFFE6FFFA)),
                  _buildSummaryCard("Pendapatan", "Rp 1.5jt", const Color(0xFFFD79A8), Icons.attach_money_rounded, const Color(0xFFFCE4EC)),
                  _buildSummaryCard("Stok Menipis", "3", const Color(0xFFFF7675), Icons.warning_amber_rounded, const Color(0xFFEBEEEE)),
                ],
              ),
              
              const SizedBox(height: 40),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Manajemen Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildMenuCard(
                context,
                icon: Icons.category_rounded,
                title: "Kelola Kategori",
                subtitle: "Atur klasifikasi produk",
                color: const Color(0xFF5F85DB),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryPage()));
                },
              ),
              
              const SizedBox(height: 12),

              _buildMenuCard(
                context,
                icon: Icons.settings_rounded,
                title: "Pengaturan Toko",
                subtitle: "Konfigurasi profil dan alamat",
                color: Colors.grey.shade700,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kartu yang Diperbaiki (Anti-Overflow)
  Widget _buildSummaryCard(String title, String value, Color color, IconData icon, Color bgIcon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20, 
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(16), // Padding dikurangi sedikit (20 -> 16) untuk lebih banyak ruang konten
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgIcon, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24), // Ikon sedikit mengecil (26 -> 24)
          ),
          
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // PERBAIKAN 2: Mengurangi jarak antara ikon dan teks
                const SizedBox(height: 8), // Dari 12 ke 8
                Text(
                  title, 
                  style: TextStyle(
                    fontSize: 11, // Font judul sedikit mengecil (13 -> 11)
                    color: Colors.grey.shade500, 
                    fontWeight: FontWeight.w600, // Sedikit lebih tebal agar tetap terbaca
                    height: 1.2
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2), // Jarak antar teks diperkecil (4 -> 2)
                Text(
                  value, 
                  style: TextStyle(
                    fontSize: 18, // Font nilai disesuaikan (20 -> 18) agar pas
                    fontWeight: FontWeight.w800, 
                    color: Colors.grey.shade800,
                    letterSpacing: -0.5
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: const TextStyle(
                      fontWeight: FontWeight.w700, 
                      color: Color(0xFF2D3436), 
                      fontSize: 15
                    )
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle, 
                    style: TextStyle(
                      fontSize: 13, 
                      color: Colors.grey.shade500
                    )
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 28),
          ],
        ),
      ),
    );
  }
}

class ListProdukWrapper extends StatelessWidget {
  const ListProdukWrapper({super.key});
  @override
  Widget build(BuildContext context) => const ListProduk();
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Profil", style: TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F85DB)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          spreadRadius: 1
                        )
                      ]
                    ),
                    child: const CircleAvatar(
                      radius: 55, 
                      backgroundColor: Color(0xFFF0F3F8), 
                      child: Icon(Icons.person, size: 50, color: Color(0xFF5F85DB))
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Color(0xFF5F85DB), shape: BoxShape.circle),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  )
                ],
              ),
              const SizedBox(height: 30),
              const Text("Admin Toko", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
              const SizedBox(height: 6),
              const Text("admin@toko.com", style: TextStyle(fontSize: 14, color: Color(0xFF636E72))),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity, 
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () { 
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false); 
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  label: const Text("Keluar Akun", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.red.withOpacity(0.04)
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}