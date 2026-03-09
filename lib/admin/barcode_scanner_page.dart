import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  // Controller untuk mengontrol kamera
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    // Penting: Matikan kamera saat halaman ditutup
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Barcode")),
      body: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture capture) {
          // Ambil barcode yang terdeteksi
          final List<Barcode> barcodes = capture.barcodes;
          
          if (barcodes.isNotEmpty) {
            final String code = barcodes.first.rawValue ?? '---';
            
            // Berhenti scan sejenak agar tidak trigger berkali-kali
            controller.stop();
            
            // Kembalikan hasil ke halaman sebelumnya
            Navigator.pop(context, code);
          }
        },
      ),
      // Overlay panduan (kotak hijau di tengah)
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: const Text(
          "Arahkan kamera ke kode batang",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}