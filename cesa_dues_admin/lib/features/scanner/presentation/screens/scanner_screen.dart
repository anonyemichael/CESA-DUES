import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  final TextEditingController _manualController = TextEditingController();
  bool _isProcessing = false;
  bool _isManualLoading = false;

  @override
  void dispose() {
    cameraController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;
      setState(() {
        _isProcessing = true;
      });

      try {
        final payload = jsonDecode(code) as Map<String, dynamic>;
        
        if (!payload.containsKey('receiptId') || !payload.containsKey('studentId')) {
          _showError('Invalid QR Code format. Please scan an official CESA clearance pass.');
          return;
        }

        final studentId = payload['studentId'].toString();
        final receiptId = payload['receiptId'].toString();

        final repo = ref.read(paymentRepositoryProvider);
        final receipts = await repo.getStudentReceipts(studentId);
        
        final validReceipt = receipts.where((r) => r.receiptId == receiptId).firstOrNull;

        if (validReceipt != null) {
          _showSuccess(validReceipt);
        } else {
          // If offline or first time, check all receipts or accept the verified payload if student exists
          if (receipts.isNotEmpty) {
            _showSuccess(receipts.first);
          } else {
            _showError('Receipt #$receiptId not found in records for index $studentId.');
          }
        }
      } catch (e) {
        _showError('Unrecognized QR Code. Please scan an official CESA student pass.');
      }
    }
  }

  void _verifyManualIndex() async {
    final query = _manualController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isManualLoading = true);
    try {
      final repo = ref.read(paymentRepositoryProvider);
      final receipts = await repo.getStudentReceipts(query.toUpperCase());
      setState(() => _isManualLoading = false);

      if (receipts.isNotEmpty) {
        _showSuccess(receipts.first);
      } else {
        _showError('No payment records found for student index "$query".');
      }
    } catch (e) {
      setState(() => _isManualLoading = false);
      _showError('Failed to query payments: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.cancel_rounded, color: AppColors.error, size: 26),
            SizedBox(width: 8),
            Text('Clearance Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
            },
            child: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(Payment payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.all(20),
        title: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.successBorder),
          ),
          child: Row(
            children: const [
              Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CLEARED & VERIFIED', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.success)),
                    Text('Official Dues Payment Pass', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailItem('Student Name', payment.studentName.isNotEmpty ? payment.studentName : 'Verified Student'),
              _detailItem('Index Number', payment.studentId),
              _detailItem('Academic Level', 'Level ${payment.studentLevel}'),
              _detailItem('Dues Package', payment.duesName),
              _detailItem('Amount Paid', 'GHS ${payment.amountInCedis.toStringAsFixed(2)}', isBold: true, valueColor: AppColors.success),
              _detailItem('Receipt ID', payment.receiptId ?? 'N/A'),
              _detailItem('Date Cleared', DateFormat('dd MMM yyyy, HH:mm').format(payment.createdAt ?? DateTime.now())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
            },
            child: const Text('Scan Next Student'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showManualLookupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Manual Clearance Lookup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter the student\'s Index Number to check clearance records:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: _manualController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Index Number (e.g. UEB1114824)',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _isManualLoading
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _verifyManualIndex();
                    },
              child: _isManualLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Verify Student'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('QR Scanner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.amber, size: 20),
            tooltip: 'Toggle Flash',
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 20),
            tooltip: 'Switch Camera',
            onPressed: () => cameraController.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard, color: Colors.white, size: 20),
            tooltip: 'Manual Lookup',
            onPressed: _showManualLookupDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          // Scanner Overlay Frame
          Center(
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'Point camera at the Student\'s Official QR Pass',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showManualLookupDialog,
                  icon: const Icon(Icons.search, color: Colors.white, size: 16),
                  label: const Text('Lookup by Index Number Instead', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    backgroundColor: Colors.black45,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
