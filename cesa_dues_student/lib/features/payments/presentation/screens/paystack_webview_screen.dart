import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/payment_controller.dart';
import '../../../receipts/presentation/controllers/receipts_controller.dart';
import '../../../dues/presentation/controllers/dues_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

/// In-App Embedded Paystack Checkout Screen.
/// Keeps the student 100% inside the app during the entire payment process.
class PaystackWebViewScreen extends ConsumerStatefulWidget {
  const PaystackWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
    required this.dues,
  });

  final String authorizationUrl;
  final String reference;
  final Dues dues;

  @override
  ConsumerState<PaystackWebViewScreen> createState() => _PaystackWebViewScreenState();
}

class _PaystackWebViewScreenState extends ConsumerState<PaystackWebViewScreen> {
  late final WebViewController _webViewController;
  int _loadingProgress = 0;
  bool _isLoading = true;
  bool _isVerifying = false;
  bool _verificationComplete = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
            _checkUrlForSuccess(url);
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _checkUrlForSuccess(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            if (_isSuccessUrl(url)) {
              _handlePaymentSuccess();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _isLoading = false;
                // Only show error if not redirecting to custom callback
                if (!_isSuccessUrl(error.url ?? '')) {
                  _errorMessage = 'Network connection interrupted. Please tap retry.';
                }
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  bool _isSuccessUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('payment-success') ||
        lower.contains('standard/success') ||
        lower.contains('status=success') ||
        lower.contains('trxref=${widget.reference.toLowerCase()}');
  }

  void _checkUrlForSuccess(String url) {
    if (_isSuccessUrl(url) && !_isVerifying && !_verificationComplete) {
      _handlePaymentSuccess();
    }
  }

  Future<void> _handlePaymentSuccess() async {
    if (_isVerifying || _verificationComplete) return;

    setState(() {
      _isVerifying = true;
    });

    final verified = await ref
        .read(paymentControllerProvider.notifier)
        .verifyPaystackPayment(widget.reference);

    if (!mounted) return;

    if (verified) {
      setState(() {
        _isVerifying = false;
        _verificationComplete = true;
      });

      // Refresh student dues & receipts cache
      ref.invalidate(studentReceiptsProvider);
      ref.invalidate(studentDuesProvider);
      ref.invalidate(currentStudentProvider);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.successBorder, width: 2),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Successful!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment of GHS ${widget.dues.amountInCedis.toStringAsFixed(2)} for "${widget.dues.name}" has been cleared and verified.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('View Official Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      setState(() {
        _isVerifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verification is pending. Please complete transaction on Paystack.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_verificationComplete) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Cancel Checkout?'),
        content: const Text('Are you sure you want to exit the checkout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Payment'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit Checkout'),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            tooltip: 'Close',
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.of(context).pop(false);
              }
            },
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock_rounded, size: 16, color: AppColors.success),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dues.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Paystack Secured • GHS ${widget.dues.amountInCedis.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
              tooltip: 'Reload Checkout',
              onPressed: () => _webViewController.reload(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: _isLoading
                ? LinearProgressIndicator(
                    value: _loadingProgress / 100.0,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 2,
                  )
                : const Divider(height: 1, color: AppColors.border),
          ),
        ),
        body: Stack(
          children: [
            // WebView
            if (_errorMessage == null)
              WebViewWidget(controller: _webViewController)
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _isLoading = true;
                          });
                          _webViewController.reload();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Connection'),
                      ),
                    ],
                  ),
                ),
              ),

            // In-App Verification Overlay
            if (_isVerifying)
              Container(
                color: Colors.black.withOpacity(0.65),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 18),
                        Text(
                          'Verifying Payment with Paystack...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Confirming your transaction and generating your official receipt.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
