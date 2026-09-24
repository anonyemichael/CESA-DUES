import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/theme/app_colors.dart';
import 'package:intl/intl.dart';

class QrReceiptScreen extends StatelessWidget {
  const QrReceiptScreen({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final receiptNumber = (payment.receiptId != null && payment.receiptId!.isNotEmpty)
        ? payment.receiptId!
        : 'CESA-REC-${payment.id.length >= 8 ? payment.id.substring(0, 8).toUpperCase() : payment.id.toUpperCase()}';

    // Generate QR Payload. We embed basic verifiable data.
    final payload = jsonEncode({
      'receiptId': receiptNumber,
      'paymentId': payment.id,
      'studentId': payment.studentId,
      'duesId': payment.duesId,
      'amount': payment.amount,
      'date': payment.createdAt?.toIso8601String(),
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt QR Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Payment Verified',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      payment.duesName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 250.0,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Receipt ID: $receiptNumber',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      payment.createdAt != null
                          ? DateFormat('MMM d, yyyy • h:mm a').format(payment.createdAt!)
                          : '',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Present this QR Code to an admin for offline event check-ins or verification.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
