// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Import halaman scanner yang sudah kamu buat sebelumnya
import 'barcode_scanner_page.dart'; 

class EditProduk extends StatefulWidget {
  final Map<String, dynamic> productData;

  const EditProduk({super.key, required this.productData});

  @override
  State<EditProduk> createState() => _EditProdukState();
}

class _EditProdukState extends State<EditProduk> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late final TextEditingController _namaController;
  late final TextEditingController _kategoriController;
  late final TextEditingController _hargaJualController;
  late final TextEditingController _hargaBeliController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _gambarController; // Untuk menampung URL manual jika perlu

  bool _isLoading = false;

  // Variabel Gambar
  File? _imageFile;
  String? _existingImageUrl; // Menyimpan URL gambar lama dari database
  final ImagePicker _picker = ImagePicker();

  // Konstanta Warna
  final Color primaryBlue = const Color(0xFF5F85DB);

  @override
  void initState() {
    super.initState();
    // Isi controller dengan data yang ada
    _namaController = TextEditingController(text: widget.productData['nama_produk']);
    _kategoriController = TextEditingController(text: widget.productData['kategori']);
    _hargaJualController = TextEditingController(text: widget.productData['harga_jual'].toString());
    _hargaBeliController = TextEditingController(text: widget.productData['harga_beli']?.toString() ?? '0');
    _barcodeController = TextEditingController(text: widget.productData['barcode'] ?? '');
    
    // Simpan URL gambar lama
    _existingImageUrl = widget.productData['gambar'];
    
    // Controller URL gambar (opsional, jika kamu ingin edit manual lewat teks)
    _gambarController = TextEditingController(text: _existingImageUrl ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kategoriController.dispose();
    _hargaJualController.dispose();
    _hargaBeliController.dispose();
    _barcodeController.dispose();
    _gambarController.dispose();
    super.dispose();
  }

  // --- FUNGSI GAMBAR (Sama seperti Tambah) ---
  
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
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _imageFile = null;
                    _existingImageUrl = null; // Hapus referensi gambar lama
                  });
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        File compressedImage = await _compressImage(File(image.path));

        if (mounted) {
          Navigator.pop(context);
          setState(() {
            _imageFile = compressedImage;
            _existingImageUrl = null; // Ganti referensi dengan file baru
          });
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memproses gambar: $e')),
          );
        }
      }
    }
  }

  Future<File> _compressImage(File file) async {
    final path = file.absolute.path;
    final lastIndex = path.lastIndexOf(RegExp(r'\.'));
    final split = path.substring(0, (lastIndex + 1));
    final outPath = '${split}compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 70,
      minWidth: 800,
      minHeight: 600,
    );

    if (result == null) {
      return file;
    }
    return File(result.path);
  }

  Future<String> _uploadImage(String fileName) async {
    if (_imageFile == null) return ''; 

    try {
      String bucketName = 'products'; 
      final path = '$fileName-${DateTime.now().millisecondsSinceEpoch}';

      await Supabase.instance.client.storage
          .from(bucketName)
          .upload(path, _imageFile!);
          
      final imageUrl = Supabase.instance.client.storage
          .from(bucketName)
          .getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      debugPrint("GAGAL Upload Image: $e");
      throw Exception("Gagal upload gambar: Cek bucket storage 'products'");
    }
  }

  // --- FUNGSI BARCODE & PDF (Sama seperti Tambah) ---

  Future<void> _scanBarcode() async {
    final scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );

    if (scannedCode != null && scannedCode.toString().isNotEmpty) {
      setState(() {
        _barcodeController.text = scannedCode.toString();
      });
    }
  }

  Future<void> _generateAndPrintBarcode() async {
    final pdf = pw.Document();
    String productName = _namaController.text.isEmpty ? 'Produk' : _namaController.text;
    String price = _hargaJualController.text.isEmpty ? '0' : _hargaJualController.text;
    String barcodeData = _barcodeController.text;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  productName,
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Rp $price',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.blue800),
                ),
                pw.SizedBox(height: 10),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: barcodeData,
                  width: 200,
                  height: 80,
                  drawText: false,
                ),
                pw.SizedBox(height: 5),
                pw.Text(barcodeData, style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Barcode_$productName.pdf',
    );
  }

  // --- FUNGSI UPDATE (LOGIKA KHUSUS EDIT) ---
  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Handle Gambar
      String? finalImageUrl;

      if (_imageFile != null) {
        // Jika user memilih gambar baru, upload
        finalImageUrl = await _uploadImage(_namaController.text);
      } else if (_existingImageUrl != null) {
        // Jika user tidak memilih gambar baru tapi ada gambar lama, pakai gambar lama
        finalImageUrl = _existingImageUrl;
      }
      // Jika keduanya null, finalImageUrl tetap null, dan kita tidak kirim key 'gambar'

      // 2. Siapkan Data Update
      Map<String, dynamic> updateData = {
        'nama_produk': _namaController.text,
        'kategori': _kategoriController.text.isEmpty ? 'Umum' : _kategoriController.text,
        'harga_jual': int.parse(_hargaJualController.text),
        'harga_beli': int.parse(_hargaBeliController.text),
        'barcode': _barcodeController.text,
      };

      // Hanya kirim 'gambar' jika ada gambar (baru atau lama)
      // Jika null, Supabase akan membiarkan kolom gambar tetap seperti sebelumnya
      if (finalImageUrl != null && finalImageUrl.isNotEmpty) {
        updateData['gambar'] = finalImageUrl;
      } else {
        // Jika user sengaja menghapus foto (tap hapus di bottom sheet)
        updateData['gambar'] = '';
      }

      // 3. Update ke Database
      await Supabase.instance.client
          .from('produk')
          .update(updateData)
          .eq('id_produk', widget.productData['id_produk']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil diperbarui'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Kembali dengan true agar list refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Edit Produk"), backgroundColor: primaryBlue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- AREA GAMBAR (LOGIKA 3 STATE) ---
              GestureDetector(
                onTap: () => _showPicker(context),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageFile != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                _imageFile!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: CircleAvatar(
                                backgroundColor: Colors.red,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () => setState(() => _imageFile = null),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _existingImageUrl != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    _existingImageUrl!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, o, s) => const Center(child: Icon(Icons.broken_image, size: 50)),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text('Tap untuk ganti / hapus', style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 50, color: primaryBlue),
                                const SizedBox(height: 10),
                                Text('Tap untuk tambah foto', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 24),

              // --- KARTU BARCODE ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Barcode Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.qr_code_scanner, color: primaryBlue),
                                onPressed: _scanBarcode,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.print, color: primaryBlue),
                                onPressed: _isLoading ? null : _generateAndPrintBarcode,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: _barcodeController.text,
                        color: Colors.black,
                        height: 50,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _barcodeController.text,
                      style: const TextStyle(letterSpacing: 2.0, fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- FORM INPUT ---
              _buildInputField(_namaController, 'Nama Produk', Icons.inventory_2_outlined, false),
              const SizedBox(height: 16),
              _buildInputField(_kategoriController, 'Kategori', Icons.category_outlined, false),
              const SizedBox(height: 16),
              _buildInputField(_hargaJualController, 'Harga Jual', Icons.sell_outlined, true),
              const SizedBox(height: 16),
              _buildInputField(_hargaBeliController, 'Harga Beli (Modal/HPP)', Icons.monetization_on_outlined, true),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _update,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('UPDATE PRODUK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
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
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
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