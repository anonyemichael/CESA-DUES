import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/id_verification_controller.dart';
import '../controllers/profile_controller.dart';

class IdVerificationScreen extends ConsumerStatefulWidget {
  const IdVerificationScreen({super.key, required this.indexNumber});

  final String indexNumber;

  @override
  ConsumerState<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends ConsumerState<IdVerificationScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _isComplete = false;
  VerificationStatus? _resultStatus;
  
  late AnimationController _animationController;
  late Animation<double> _laserAnimation;

  final List<String> _logs = [];
  Timer? _logTimer;

  final List<String> _simulatedLogs = [
    'Initializing camera module...',
    'Image captured successfully.',
    'Enhancing contrast for OCR...',
    'Extracting text regions...',
    'Locating KNUST Student ID format...',
    'Found matching Index Number...',
    'Cross-referencing database...',
    'Finalizing verification...',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logTimer?.cancel();
    super.dispose();
  }

  void _startSimulation() async {
    setState(() {
      _isScanning = true;
      _isComplete = false;
      _logs.clear();
      _logs.add('Starting ID Verification...');
    });

    _animationController.repeat(reverse: true);

    // Simulate logs popping up every 400ms
    int logIndex = 0;
    _logTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (logIndex < _simulatedLogs.length) {
        setState(() {
          _logs.insert(0, _simulatedLogs[logIndex]);
        });
        logIndex++;
      } else {
        timer.cancel();
      }
    });

    final newStatus = await ref.read(idVerificationControllerProvider.notifier)
        .simulateScanAndVerify(widget.indexNumber);

    _animationController.stop();
    
    if (mounted) {
      setState(() {
        _isScanning = false;
        _isComplete = true;
        _resultStatus = newStatus;
        if (newStatus == VerificationStatus.verified) {
          _logs.insert(0, 'SUCCESS: ID Verified!');
        } else if (newStatus == VerificationStatus.pending) {
          _logs.insert(0, 'WARNING: OCR Failed. Sent for manual review.');
        } else {
          _logs.insert(0, 'ERROR: Verification failed.');
        }
      });
      
      // Refresh current student state
      ref.invalidate(currentStudentProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Student ID'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Upload a clear picture of your Student ID card. Our AI will automatically extract your Index Number and verify your account.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Simulated ID Card with Laser Animation
                Center(
                  child: Container(
                    width: 300,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Placeholder ID Card visual
                        const Center(
                          child: Icon(Icons.badge, size: 80, color: Colors.grey),
                        ),
                        const Positioned(
                          top: 16,
                          left: 16,
                          child: Text('STUDENT ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                        // Laser Animation
                        if (_isScanning)
                          AnimatedBuilder(
                            animation: _laserAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: _laserAnimation.value * 180, // Approximate height
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Action Button
                if (!_isScanning && !_isComplete)
                  ElevatedButton.icon(
                    onPressed: _startSimulation,
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('Upload & Scan ID'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                
                if (_isComplete)
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _resultStatus == VerificationStatus.verified 
                          ? AppColors.success 
                          : AppColors.warning,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Return to Dashboard', style: TextStyle(color: Colors.white)),
                  ),

                const SizedBox(height: 32),

                // Terminal Logs Box
                if (_logs.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          Color textColor = Colors.greenAccent;
                          if (log.startsWith('WARNING')) textColor = Colors.orangeAccent;
                          if (log.startsWith('ERROR')) textColor = Colors.redAccent;
                          if (log.startsWith('SUCCESS')) textColor = Colors.white;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              '> $log',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: textColor,
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
