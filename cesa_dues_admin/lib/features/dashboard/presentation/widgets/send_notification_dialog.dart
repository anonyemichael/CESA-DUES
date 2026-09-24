import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../controllers/send_notification_controller.dart';

class SendNotificationDialog extends ConsumerStatefulWidget {
  const SendNotificationDialog({super.key, this.student});

  final Student? student;

  @override
  ConsumerState<SendNotificationDialog> createState() => _SendNotificationDialogState();
}

class _SendNotificationDialogState extends ConsumerState<SendNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  late NotificationTarget _target;

  @override
  void initState() {
    super.initState();
    _target = widget.student != null ? NotificationTarget.personal : NotificationTarget.all;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _send() {
    if (_formKey.currentState!.validate()) {
      ref.read(sendNotificationControllerProvider.notifier).sendNotification(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            target: _target,
            studentId: widget.student?.indexNumber,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(
      sendNotificationControllerProvider,
      (_, state) {
        state.when(
          data: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification sent successfully')),
            );
            Navigator.of(context).pop();
          },
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $error')),
            );
          },
          loading: () {},
        );
      },
    );

    final isLoading = ref.watch(sendNotificationControllerProvider).isLoading;

    return AlertDialog(
      title: const Text('Send Notification'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter a title' : null,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Enter a message' : null,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<NotificationTarget>(
                value: _target,
                decoration: const InputDecoration(
                  labelText: 'Target Audience',
                  border: OutlineInputBorder(),
                ),
                items: [
                  NotificationTarget.all,
                  NotificationTarget.level100,
                  NotificationTarget.level200,
                  NotificationTarget.level300,
                  NotificationTarget.level400,
                  NotificationTarget.unpaid,
                  if (widget.student != null) NotificationTarget.personal,
                ].map((target) {
                  return DropdownMenuItem(
                    value: target,
                    child: Text(target.label),
                  );
                }).toList(),
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _target = value;
                          });
                        }
                      },
              ),
            ],
          ),
        )),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _send,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send'),
        ),
      ],
    );
  }
}
