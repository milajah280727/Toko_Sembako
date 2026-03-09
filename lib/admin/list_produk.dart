// ignore_for_file: use_build_context_synchronously, deprecated_member_use, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tambah_produk.dart';
import 'edit_produk.dart';

class ListProduk extends StatefulWidget {
  const ListProduk({super.key});

  @override
  State<ListProduk> createState() => _ListProdukState();
}

class _ListProdukState extends State<ListProduk> {
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();
  final Color primaryBlue = const Color(0xFF5F85DB);

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final nama = product['nama_produk'].toString().toLowerCase();
        final kategori = product['kategori'].toString().toLowerCase();
        return nama.contains(query) || kategori.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final productsResponse = await Supabase.instance.client
          .from('produk')
          .select('*')
          .order('is_active', ascending: false)
          .order('nama_produk', ascending: true);

      final stocksResponse = await Supabase.instance.client
          .from('stok_batch')
          .select('id_produk, jumlah_stok');

      Map<int, int> stockMap = {};
      for (var batch in stocksResponse) {
        int productId = batch['id_produk'];
        int qty = batch['jumlah_stok'];
        if (stockMap.containsKey(productId)) {
          stockMap[productId] = stockMap[productId]! + qty;
        } else {
          stockMap[productId] = qty;
        }
      }

      List<Map<String, dynamic>> mergedData = [];
      for (var product in productsResponse) {
        int productId = product['id_produk'];
        int totalStock = stockMap[productId] ?? 0;
        mergedData.add({...product, 'total_stok': totalStock});
      }

      setState(() {
        _allProducts = mergedData;
        _filterProducts();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    }
  }

  Future<bool> _hasTransactionHistory(int productId) async {
    try {
      final response = await Supabase.instance.client.from('detail_transaksi').select('id_transaksi').eq('id_produk', productId).limit(1);
      return response.isNotEmpty;
    } catch (e) { return false; }
  }

  Future<void> _deleteProduct(int id, String namaProduk) async {
    final hasHistory = await _hasTransactionHistory(id);
    if (hasHistory) {
      showDialog(context: context, builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.info_outline, color: Colors.orange), SizedBox(width: 8), Text("Peringatan")]),
        content: Text('Produk "$namaProduk" tercatat dalam riwayat transaksi.\n\nGunakan opsi "Nonaktifkan" untuk menyembunyikannya tanpa menghapus data laporan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(context); _deactivateProduct(id); },
            icon: const Icon(Icons.block, size: 18),
            label: const Text('Nonaktifkan', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ));
      return;
    }

    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Hapus Permanen?", style: TextStyle(color: Colors.red)),
      content: Text('Data "$namaProduk" akan dihapus selamanya.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus')),
      ],
    ));

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('produk').delete().eq('id_produk', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk dihapus'), backgroundColor: Colors.green));
          _fetchProducts();
        }
      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'))); }
    }
  }

  Future<void> _deactivateProduct(int id) async {
    try {
      await Supabase.instance.client.from('produk').update({'is_active': false}).eq('id_produk', id);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk dinonaktifkan'))); _fetchProducts(); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'))); }
  }

  Future<void> _reactivateProduct(int id, String namaProduk) async {
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Aktifkan Kembali?"),
      content: Text("Tampilkan \"$namaProduk\" di kasir?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: primaryBlue), child: const Text('Aktifkan')),
      ],
    ));
    if (confirm == true) {
      try {
        await Supabase.instance.client.from('produk').update({'is_active': true}).eq('id_produk', id);
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk aktif kembali'))); _fetchProducts(); }
      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      // Modern White AppBar
      appBar: AppBar(
        
        title: const Text("Daftar Produk", style: TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F85DB)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _fetchProducts)],
      ),
      body: Column(
        children: [
          // Modern Floating Search Bar
          Container(
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.cancel, color: Colors.grey, size: 20), onPressed: () { _searchController.clear(); _filterProducts(); })
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) :
            _filteredProducts.isEmpty ? _buildEmptyState() :
            RefreshIndicator(
              onRefresh: _fetchProducts,
              color: primaryBlue,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index]),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const TambahProduk())); if (result == true) _fetchProducts(); },
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    int totalStock = item['total_stok'] ?? 0;
    bool isOutOfStock = totalStock == 0;
    bool isActive = item['is_active'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: isActive ? null : Border.all(color: Colors.red.shade100, width: 1),
      ),
      child: InkWell(
        onTap: () { if (!isActive) _reactivateProduct(item['id_produk'], item['nama_produk']); },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item['gambar'] != null && item['gambar'].toString().isNotEmpty
                    ? ColorFiltered(
                        colorFilter: ColorFilter.mode(isActive ? Colors.transparent : Colors.grey, BlendMode.saturation),
                        child: Image.network(item['gambar'], width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c, o, s) => _buildPlaceholderImage(isActive)),
                      )
                    : _buildPlaceholderImage(isActive),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item['nama_produk'] ?? 'Tanpa Nama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF2D3436) : Colors.red.shade900), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (!isActive) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)), child: const Text("NON-AKTIF", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item['kategori'] ?? 'Umum', style: TextStyle(fontSize: 13, color: isActive ? Colors.grey.shade500 : Colors.red.shade300)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rp ${item['harga_jual']}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isActive ? primaryBlue : Colors.red.shade700)),
                        if (isActive) Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: isOutOfStock ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: (isOutOfStock ? Colors.red : Colors.green).withOpacity(0.2))),
                          child: Text("Stok: $totalStock", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOutOfStock ? Colors.red.shade700 : Colors.green.shade700)),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              if (isActive) PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
                onSelected: (value) async {
                  if (value == 'edit') { final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditProduk(productData: item))); if (result == true) _fetchProducts(); }
                  else if (value == 'delete') _deleteProduct(item['id_produk'], item['nama_produk']);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 8), Text('Edit')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.red), SizedBox(width: 8), Text('Hapus')])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(bool isActive) => Container(width: 80, height: 80, color: isActive ? Colors.grey.shade100 : Colors.red.shade100, child: Icon(Icons.image, color: isActive ? Colors.grey.shade300 : Colors.red.shade200));

  Widget _buildEmptyState() {
    bool isSearching = _searchController.text.isNotEmpty;
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isSearching ? Icons.search_off_rounded : Icons.inventory_2_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text(isSearching ? 'Produk tidak ditemukan' : 'Belum ada data produk', style: TextStyle(color: Colors.grey.shade500))]));
  }
}