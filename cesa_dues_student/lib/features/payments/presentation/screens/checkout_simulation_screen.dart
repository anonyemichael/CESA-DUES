import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/payment_controller.dart';

class PaystackCheckoutDialog extends ConsumerStatefulWidget {
  const PaystackCheckoutDialog({super.key, required this.dues});
  final Dues dues;

  @override
  ConsumerState<PaystackCheckoutDialog> createState() => _PaystackCheckoutDialogState();
}

class _PaystackCheckoutDialogState extends ConsumerState<PaystackCheckoutDialog> {
  String? _reference;
  bool _openedPaystack = false;

  void _payWithPaystack() async {
    final res = await ref
        .read(paymentControllerProvider.notifier)
        .initiatePaystackPayment(widget.dues);

    if (mounted) {
      if (res != null) {
        setState(() {
          _reference = res['reference'] as String?;
          _openedPaystack = true;
        });
      } else {
        final error = ref.read(paymentControllerProvider).error;
        final msg = error is AppException ? error.message : 'Could not launch payment checkout.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _confirmPayment() async {
    final refCode = _reference ?? 'CESA-${DateTime.now().year}';
    final verified = await ref
        .read(paymentControllerProvider.notifier)
        .verifyPaystackPayment(refCode);

    if (mounted) {
      if (verified) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful! Official CESA receipt generated.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verification pending. If you completed payment, please tap again.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(paymentControllerProvider).isLoading;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pay with Paystack'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount:', style: TextStyle(fontSize: 16)),
              Text(
                'GHS ${widget.dues.amountInCedis.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.dues.name,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Accepts MTN MoMo, Telecel Cash, AT Money, and Cards.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        if (!isProcessing)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        if (!isProcessing && !_openedPaystack)
          ElevatedButton(
            onPressed: _payWithPaystack,
            child: const Text('Proceed to Paystack'),
          ),
        if (!isProcessing && _openedPaystack)
          ElevatedButton(
            onPressed: _confirmPayment,
            child: const Text('I Have Paid'),
          ),
      ],
    );
  }
}
