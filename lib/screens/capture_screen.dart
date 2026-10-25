import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/expense_store.dart';
import 'review_screen.dart';

/// Linux-desktop receipt import. The Flutter `camera` plugin has no Linux
/// implementation, so receipts are loaded from image files (photo, scan or
/// screenshot) through the native file chooser.
class CaptureScreen extends StatefulWidget {
  final ExpenseStore store;
  const CaptureScreen({super.key, required this.store});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  String? _error;

  Future<void> _pickImage() async {
    setState(() => _error = null);
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x != null) await _goReview(File(x.path));
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not open the image: $e');
    }
  }

  Future<void> _goReview(File f) async {
    if (!mounted) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => ReviewScreen(store: widget.store, image: f)),
    );
    if (saved == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan receipt')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.document_scanner, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Choose a photo or scan of a receipt.\n'
              'Text is recognised offline on this computer.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose image…'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center),
            ],
          ]),
        ),
      ),
    );
  }
}
