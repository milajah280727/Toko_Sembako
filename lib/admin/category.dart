import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  final Color primaryBlue = const Color(0xFF5F85DB);
  
  // Controller untuk input tambah/edit
  final TextEditingController _categoryNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  // --- READ: Ambil semua kategori ---
  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('*')
          .order('nama_kategori', ascending: true);

      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat: $e')));
    }
  }

  // --- CREATE: Tambah Kategori Baru ---
  Future<void> _showAddCategoryDialog() async {
    _categoryNameController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Tambah Kategori Baru"),
        content: TextField(
          controller: _categoryNameController,
          decoration: const InputDecoration(hintText: "Nama kategori..."),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirmed == true && _categoryNameController.text.isNotEmpty) {
      try {
        await Supabase.instance.client.from('categories').insert({
          'nama_kategori': _categoryNameController.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori ditambahkan'), backgroundColor: Colors.green));
          _fetchCategories();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  // --- UPDATE: Ubah Nama Kategori ---
  Future<void> _editCategory(int id, String currentName) async {
    _categoryNameController.text = currentName;
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Ubah Nama Kategori"),
        content: TextField(controller: _categoryNameController),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (_categoryNameController.text.isNotEmpty) Navigator.pop(context, _categoryNameController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newName != null && newName != currentName) {
      try {
        await Supabase.instance.client
            .from('categories')
            .update({'nama_kategori': newName})
            .eq('id_kategori', id);
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori diupdate'), backgroundColor: Colors.green));
          _fetchCategories();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  // --- DELETE: Hapus Kategori ---
  Future<void> _deleteCategory(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus Kategori?", style: TextStyle(color: Colors.red)),
        content: const Text("Menghapus kategori akan menghapusnya dari daftar pilihan pada tambah produk. Produk yang sudah ada tidak akan terhapus."),
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
        await Supabase.instance.client.from('categories').delete().eq('id_kategori', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori dihapus')));
          _fetchCategories();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Manajemen Kategori", style: TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F85DB)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCategories)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("Belum ada kategori", style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text("Tekan + untuk menambah", style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return _buildCategoryCard(cat['id_kategori'], cat['nama_kategori']);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryCard(int id, String name) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.category, color: Color(0xFF5F85DB), size: 28),
            ),
            const Spacer(),
            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => _editCategory(id, name),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _deleteCategory(id),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}