// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class BatchProdukPage extends StatefulWidget {
  const BatchProdukPage({super.key});

  @override
  State<BatchProdukPage> createState() => _BatchProdukPageState();
}

class _BatchProdukPageState extends State<BatchProdukPage> {
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  final Color primaryBlue = const Color(0xFF5F85DB);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // --- FUNGSI AMBIL DATA ---
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Ambil Data Batch beserta Nama Produk terkait
      final batchResponse = await Supabase.instance.client
          .from('stok_batch')
          .select('*, produk(nama_produk)')
          .order('tanggal_masuk', ascending: false);

      // 2. Ambil Data Produk untuk Dropdown saat menambah batch
      final productResponse = await Supabase.instance.client
          .from('produk')
          .select('id_produk, nama_produk')
          .order('nama_produk', ascending: true);

      setState(() {
        _batches = List<Map<String, dynamic>>.from(batchResponse);
        _products = List<Map<String, dynamic>>.from(productResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- FUNGSI HAPUS BATCH ---
  Future<void> _deleteBatch(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus Batch?", style: TextStyle(color: Colors.red)),
        content: const Text("Tindakan ini akan mengurangi stok produk. Lanjutkan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('stok_batch').delete().eq('id_batch', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch dihapus')));
          _fetchData(); // Panggil _fetchData, bukan _fetchProducts
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }

  // --- TAMPILKAN DIALOG TAMBAH BATCH ---
  void _showAddBatchDialog() {
    final formKey = GlobalKey<FormState>();
    final qtyController = TextEditingController();
    final priceController = TextEditingController();
    
    // State Dropdown & Tanggal
    int? selectedProductId;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30)); // Default exp 30 hari ke depan

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Tambah Stok Masuk", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown Pilih Produk
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Pilih Produk',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: _products.map((prod) {
                      return DropdownMenuItem<int>(
                        value: prod['id_produk'],
                        child: Text(prod['nama_produk']), // Jangan gunakan const Text di sini
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedProductId = value);
                    },
                    validator: (value) => value == null ? 'Pilih produk' : null,
                  ),
                  const SizedBox(height: 16),

                  // Input Jumlah
                  TextFormField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Stok',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Masukkan jumlah' : null,
                  ),
                  const SizedBox(height: 16),

                  // Input Harga Beli Satuan
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Harga Beli Satuan (Modal)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Masukkan harga' : null,
                  ),
                  const SizedBox(height: 16),

                  // Input Tanggal Exp
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Jangan gunakan const Text karena tanggal dinamis
                          Text(DateFormat('dd MMM yyyy').format(selectedDate), style: const TextStyle(fontSize: 16)),
                          const Icon(Icons.calendar_today, color: Color(0xFF5F85DB))
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await Supabase.instance.client.from('stok_batch').insert({
                      'id_produk': selectedProductId,
                      'jumlah_stok': int.parse(qtyController.text),
                      'harga_beli_satuan': int.parse(priceController.text),
                      'tanggal_exp': selectedDate.toIso8601String().split('T')[0],
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stok berhasil ditambahkan'), backgroundColor: Colors.green),
                      );
                      _fetchData();
                    }
                  } catch (e) {
                    // Gunakan context yang aman
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Manajemen Batch Stok", style: TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F85DB)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _fetchData, // Pastikan memanggil _fetchData
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _batches.isEmpty
              ? const Center(child: Text("Belum ada data batch stok"))
              : RefreshIndicator(
                  onRefresh: _fetchData, // Pastikan memanggil _fetchData
                  color: primaryBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                    itemCount: _batches.length,
                    itemBuilder: (context, index) {
                      final batch = _batches[index];
                      final product = batch['produk']; 
                      
                      String expDate = batch['tanggal_exp'] ?? '-';
                      String entryDate = batch['tanggal_masuk'] != null 
                          ? DateFormat('dd MMM yyyy').format(DateTime.parse(batch['tanggal_masuk'])) 
                          : '-';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), 
                          side: BorderSide(color: Colors.grey.shade100, width: 1)
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      // Perbaikan deprecated: withValues
                                      color: primaryBlue.withValues(alpha: 0.1), 
                                      borderRadius: BorderRadius.circular(10)
                                    ),
                                    child: Icon(Icons.inventory, color: primaryBlue, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      product != null ? product['nama_produk'] : 'Produk Dihapus',
                                      style: const TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold, 
                                        color: Color(0xFF2D3436)
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                    onPressed: () => _deleteBatch(batch['id_batch']),
                                  ),
                                ],
                              ),
                              const Divider(height: 30),
                              Row(
                                children: [
                                  Expanded(child: _buildInfoCol("Jumlah", "${batch['jumlah_stok']} pcs")),
                                  Expanded(child: _buildInfoCol("Harga Beli", "Rp ${batch['harga_beli_satuan']}")),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildInfoCol("Tgl Masuk", entryDate, small: true)),
                                  Expanded(child: _buildInfoCol("Tgl Kadaluarsa", expDate, small: true, isExp: true)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: primaryBlue, 
          borderRadius: BorderRadius.circular(16),
          // Perbaikan deprecated: withValues
          boxShadow: [BoxShadow(color: primaryBlue.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))]
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: _showAddBatchDialog,
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value, {bool small = false, bool isExp = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: small ? 11 : 12, 
            color: Colors.grey.shade500, 
            fontWeight: FontWeight.w500
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: small ? 13 : 15, 
            fontWeight: FontWeight.bold, 
            color: isExp ? Colors.orange : const Color(0xFF2D3436)
          ),
        ),
      ],
    );
  }
}