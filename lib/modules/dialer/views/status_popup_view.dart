// lib/modules/dialer/views/status_popup_view.dart
import 'package:flutter/material.dart';

class StatusPopupView extends StatefulWidget {
  const StatusPopupView({
    super.key,
    required this.loadStatuses,
    required this.onSubmit,
    this.title = 'Select Call Outcome',
  });

  final Future<List<String>> Function() loadStatuses;
  final Future<void> Function(String status) onSubmit;
  final String title;

  static Future<void> show({
    required BuildContext context,
    required Future<List<String>> Function() loadStatuses,
    required Future<void> Function(String status) onSubmit,
    String title = 'Select Call Outcome',
    bool barrierDismissible = true,
  }) {
    // showDialog returns a Future that completes after Navigator.pop. [web:370]
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => StatusPopupView(
        loadStatuses: loadStatuses,
        onSubmit: onSubmit,
        title: title,
      ),
    );
  }

  @override
  State<StatusPopupView> createState() => _StatusPopupViewState();
}

class _StatusPopupViewState extends State<StatusPopupView> {
  late Future<List<String>> _future;
  String? _selected;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _future = widget.loadStatuses();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            FutureBuilder<List<String>>(
              future: _future,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  );
                }
                if (snap.hasError) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Failed to load statuses',
                        style: TextStyle(color: Colors.red),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _future = widget.loadStatuses()),
                        child: const Text('Retry'),
                      ),
                    ],
                  );
                }
                final options = snap.data ?? const <String>[];
                if (options.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No statuses available'),
                  );
                }
                _selected ??= options.first;
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView(
                    shrinkWrap: true,
                    children: options.map((s) {
                      return RadioListTile<String>(
                        value: s,
                        groupValue: _selected,
                        title: Text(s),
                        onChanged: _submitting
                            ? null
                            : (val) => setState(() => _selected = val),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Removed the Cancel button as requested; only Submit remains. [web:370]
                ElevatedButton(
                  onPressed: (_selected == null || _submitting)
                      ? null
                      : () async {
                          setState(() {
                            _submitting = true;
                            _error = null;
                          });
                          try {
                            await widget.onSubmit(_selected!);
                            if (mounted) Navigator.of(context).pop();
                          } catch (e) {
                            setState(() {
                              _error = 'Submit failed: $e';
                            });
                          } finally {
                            if (mounted) {
                              setState(() {
                                _submitting = false;
                              });
                            }
                          }
                        },
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
