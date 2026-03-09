// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:loginpage/admin/barcode_scanner_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TambahProduk extends StatefulWidget {
  const TambahProduk({super.key});

  @override
  State<TambahProduk> createState() => _TambahProdukState();
}

class _TambahProdukState extends State<TambahProduk> {
  // Controllers
  final _namaController = TextEditingController();
  final _hargaJualController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  final _barcodeController = TextEditingController();

  bool _isLoading = false;

  // Gambar
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  // Konstanta Warna
  final Color primaryBlue = const Color(0xFF5F85DB);

  // --- STATE KATEGORI (UPDATE) ---
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _barcodeController.text = _generateRandomBarcode();
    _fetchCategories(); // Ambil kategori dari tabel 'categories'
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaJualController.dispose();
    _hargaBeliController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  // --- FUNGSI AMBIL KATEGORI DARI TABEL 'CATEGORIES' ---
  Future<void> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('*')
          .order('nama_kategori', ascending: true);
      
      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first['nama_kategori'];
        } else {
          _selectedCategory = 'Umum'; // Fallback jika tabel kosong
        }
        _isLoadingCategories = false;
      });
    } catch (e) {
      print("Error fetching categories: $e");
      // Jika error (misal tabel belum dibuat), gunakan default
      setState(() {
        _categories = [];
        _selectedCategory = 'Umum';
        _isLoadingCategories = false;
      });
    }
  }

  // --- FUNGSI UTILITAS ---

  String _generateRandomBarcode() {
    final random = Random();
    var barcode = '';
    for (int i = 0; i < 8; i++) {
      barcode += random.nextInt(10).toString();
    }
    return barcode;
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF5F85DB)),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFF5F85DB)),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
      try {
        File compressedImage = await _compressImage(File(image.path));
        if (mounted) { Navigator.pop(context); setState(() { _imageFile = compressedImage; }); }
      } catch (e) {
        if (mounted) Navigator.pop(context);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memproses gambar: $e')));
      }
    }
  }

  Future<File> _compressImage(File file) async {
    final path = file.absolute.path;
    final lastIndex = path.lastIndexOf(RegExp(r'\.'));
    final split = path.substring(0, (lastIndex + 1));
    final outPath = '${split}compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    var result = await FlutterImageCompress.compressAndGetFile(file.absolute.path, outPath, quality: 70, minWidth: 800, minHeight: 600);
    if (result == null) return file;
    return File(result.path);
  }

  Future<String> _uploadImage(String fileName) async {
    if (_imageFile == null) return '';
    try {
      String bucketName = 'products-image'; 
      final path = '$fileName-${DateTime.now().millisecondsSinceEpoch}';
      await Supabase.instance.client.storage.from(bucketName).upload(path, _imageFile!);
      final imageUrl = Supabase.instance.client.storage.from(bucketName).getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      debugPrint("GAGAL Upload Image: $e");
      throw Exception("Gagal upload gambar: Cek bucket storage 'products'");
    }
  }

  Future<void> _scanBarcode() async {
    final scannedCode = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BarcodeScannerPage()));
    if (scannedCode != null && scannedCode.toString().isNotEmpty) {
      setState(() { _barcodeController.text = scannedCode.toString(); });
    }
  }

  Future<void> _generateAndPrintBarcode() async {
    final pdf = pw.Document();
    String productName = _namaController.text.isEmpty ? 'Produk Baru' : _namaController.text;
    String price = _hargaJualController.text.isEmpty ? '0' : _hargaJualController.text;
    String barcodeData = _barcodeController.text;
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a6, margin: const pw.EdgeInsets.all(10), build: (pw.Context context) {
      return pw.Center(child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
        pw.Text(productName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text('Rp $price', style: pw.TextStyle(fontSize: 14, color: PdfColors.blue800)),
        pw.SizedBox(height: 10),
        pw.BarcodeWidget(barcode: pw.Barcode.code128(), data: barcodeData, width: 200, height: 80, drawText: false),
        pw.SizedBox(height: 5),
        pw.Text(barcodeData, style: const pw.TextStyle(fontSize: 12)),
      ]));
    }));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Barcode_$productName.pdf');
  }

  Future<void> _saveProduct() async {
    if (_namaController.text.isEmpty || _hargaJualController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama dan Harga Jual wajib diisi!'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      String imageUrl = '';
      if (_imageFile != null) imageUrl = await _uploadImage(_namaController.text);
      int parsedHargaBeli = 0;
      if (_hargaBeliController.text.isNotEmpty) parsedHargaBeli = int.parse(_hargaBeliController.text);

      final productData = {
        'nama_produk': _namaController.text,
        'kategori': _selectedCategory ?? 'Umum', // Mengambil dari Dropdown Master Kategori
        'harga_jual': int.parse(_hargaJualController.text),
        'harga_beli': parsedHargaBeli,
        'barcode': _barcodeController.text,
        'gambar': imageUrl,
      };

      await Supabase.instance.client.from('produk').insert(productData);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk Berhasil Ditambahkan'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Menyimpan: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Tambah Produk"), backgroundColor: primaryBlue, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Area Gambar
            GestureDetector(
              onTap: () => _showPicker(context),
              child: Container(
                width: double.infinity, height: 200,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                child: _imageFile != null ? Stack(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_imageFile!, width: double.infinity, height: double.infinity, fit: BoxFit.cover)),
                    Positioned(top: 10, right: 10, child: CircleAvatar(backgroundColor: Colors.red, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _imageFile = null))))
                  ],
                ) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 50, color: primaryBlue),
                  const SizedBox(height: 10), Text('Tap untuk ambil foto / galeri', style: TextStyle(color: Colors.grey[600]))
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // Kartu Barcode
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Barcode Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(children: [
                      Container(decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: Icon(Icons.qr_code_scanner, color: primaryBlue), onPressed: _scanBarcode, constraints: const BoxConstraints(), padding: const EdgeInsets.all(8))),
                      const SizedBox(width: 8),
                      Container(decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: Icon(Icons.print, color: primaryBlue), onPressed: _isLoading ? null : _generateAndPrintBarcode, constraints: const BoxConstraints(), padding: const EdgeInsets.all(8))),
                    ]),
                  ]),
                  const SizedBox(height: 20),
                  Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: BarcodeWidget(barcode: Barcode.code128(), data: _barcodeController.text, color: Colors.black, height: 50)),
                  const SizedBox(height: 10),
                  Text(_barcodeController.text, style: const TextStyle(letterSpacing: 2.0, fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Input Field
            _buildInputField(_namaController, 'Nama Produk', Icons.inventory_2_outlined, false),
            const SizedBox(height: 16),
            
            // --- UPDATE KATEGORI (DROPDOWN DARI TABEL CATEGORIES) ---
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Kategori', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: DropdownButtonHideUnderline(
                  child: _isLoadingCategories
                      ? const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
                      : DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          hint: const Text('Pilih Kategori'),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF5F85DB)),
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                          items: _categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat['nama_kategori'],
                              child: Text(cat['nama_kategori']),
                            );
                          }).toList(),
                          onChanged: (String? newValue) { setState(() { _selectedCategory = newValue; }); },
                        ),
                ),
              ),
            ]),
            
            const SizedBox(height: 16),
            _buildInputField(_hargaJualController, 'Harga Jual', Icons.sell_outlined, true),
            const SizedBox(height: 16),
            _buildInputField(_hargaBeliController, 'Harga Beli (Modal/HPP)', Icons.monetization_on_outlined, true),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
                child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('SIMPAN PRODUK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon, bool isNumber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            filled: true, fillColor: Colors.white,
            prefixIcon: Icon(icon, color: primaryBlue),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryBlue, width: 2)),
          ),
        ),
      ],
    );
  }
}