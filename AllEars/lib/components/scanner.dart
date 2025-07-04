// components/scanner.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:app/components/text.dart'; // Assuming this path is correct

class QRScannerPage extends StatefulWidget {
  final ValueChanged<String> onUrlScanned;

  const QRScannerPage({super.key, required this.onUrlScanned});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  String _scanResult = 'Scan a QR code (URL)';
  bool _isValidating = false;
  bool _isScanEnabled = true; // Control scanning to avoid multiple detections

  Future<bool> _testApiUrl(String url) async {
    final testUrl = url.trim();
    if (!testUrl.startsWith('http://') && !testUrl.startsWith('https://')) {
      return false; // Ensure it's a valid URL format
    }
    try {
      // Use the root endpoint '/' for testing as per your request
      final response = await http.get(
        Uri.parse('$testUrl/'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } on http.ClientException {
      return false;
    } catch (e) {
      return false;
    }
  }

  void _handleBarcode(BarcodeCapture barcodes) async {
    if (!_isScanEnabled || barcodes.barcodes.isEmpty) {
      return;
    }

    final String? scannedUrl = barcodes.barcodes.first.rawValue;

    if (scannedUrl == null || scannedUrl.isEmpty) {
      setState(() {
        _scanResult = 'No URL found in QR code.';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _isScanEnabled = false; // Disable scanning during validation
      _scanResult = 'Validating URL: $scannedUrl';
    });

    final bool isValid = await _testApiUrl(scannedUrl);

    if (mounted) {
      setState(() {
        _isValidating = false;
      });
      if (isValid) {
        widget.onUrlScanned(scannedUrl);
        // Optionally navigate back or show a success message
        if (mounted) {
          Navigator.of(context).pop(); // Go back to the previous screen (room.dart)
        }
      } else {
        setState(() {
          _scanResult = 'Invalid or unreachable URL. Please scan a valid API URL.';
          _isScanEnabled = true; // Re-enable scanning if invalid
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBD7),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.normal, // Adjust as needed
              detectionTimeoutMs: 1000, // Debounce detection
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 60, left: 24, right: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3F4D86).withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/img/pet/head.gif', // Your GIF
                    height: 80,
                    width: 80,
                  ),
                  const SizedBox(height: 10),
                  const Head1(
                    'Scan API QR',
                    color: Color(0xFFFFEBD7),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Head2(
                    _scanResult,
                    color: Colors.white70,
                    textAlign: TextAlign.center,
                    weight: 400,
                  ),
                  if (_isValidating) ...[
                    const SizedBox(height: 10),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFEBD7)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF3F4D86)),
                label: const Text(
                  'Cancel Scan',
                  style: TextStyle(color: Color(0xFF3F4D86)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEBD7),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}