import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/expense_store.dart';
import '../models/expense.dart';
import '../services/image_service.dart';
import '../services/ocr_service.dart';

/// Runs on-device OCR on [image] (or edits an existing [expense]) and lets the
/// user correct every field before saving.
class ReviewScreen extends StatefulWidget {
  final ExpenseStore store;
  final File? image;
  final Expense? expense;
  const ReviewScreen({super.key, required this.store, this.image, this.expense});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _form = GlobalKey<FormState>();
  final _merchant = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  ExpenseCategory _category = ExpenseCategory.food;

  OcrService? _ocr;
  String _raw = '';
  bool _scanning = false;
  String? _ocrInfo;

  bool get _editing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      _merchant.text = e.merchant;
      _amount.text = e.amountVnd.toString();
      _note.text = e.note ?? '';
      _date = e.date;
      _category = e.category;
    } else if (widget.image != null) {
      _runOcr();
    }
  }

  Future<void> _runOcr() async {
    setState(() => _scanning = true);
    _ocr = OcrService();
    try {
      final r = await _ocr!.scan(widget.image!);
      _raw = r.rawText;
      final p = r.parsed;
      setState(() {
        if (p.merchant != null) _merchant.text = p.merchant!;
        if (p.totalVnd != null) _amount.text = p.totalVnd.toString();
        if (p.date != null) _date = p.date!;
        _category = p.suggestedCategory;
        _ocrInfo =
            'OCR finished in ${r.elapsed.inMilliseconds} ms (Tesseract, offline). '
            'Check the fields below.';
      });
    } catch (e) {
      setState(() => _ocrInfo = 'OCR failed: $e — enter details manually.');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  void dispose() {
    _ocr?.dispose();
    _merchant.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final amount = int.parse(_amount.text.replaceAll(RegExp(r'[^\d]'), ''));
    String? thumb = widget.expense?.thumbnailPath;
    if (widget.image != null) {
      thumb = await ImageService.cacheThumbnail(widget.image!);
    }
    final e = Expense(
      id: widget.expense?.id,
      merchant: _merchant.text.trim(),
      amountVnd: amount,
      date: _date,
      category: _category,
      thumbnailPath: thumb,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    _editing ? await widget.store.edit(e) : await widget.store.add(e);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final thumbFile = widget.image ??
        (widget.expense?.thumbnailPath != null
            ? File(widget.expense!.thumbnailPath!)
            : null);

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit expense' : 'Review receipt')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (thumbFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(thumbFile,
                    height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            if (_scanning)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: LinearProgressIndicator(),
              ),
            if (_ocrInfo != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_ocrInfo!,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _merchant,
              decoration: const InputDecoration(
                  labelText: 'Merchant', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Total (VND)',
                  suffixText: 'đ',
                  border: OutlineInputBorder()),
              validator: (v) {
                final n = int.tryParse((v ?? '').replaceAll(RegExp(r'[^\d]'), ''));
                return (n == null || n <= 0) ? 'Enter a valid amount' : null;
              },
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Date', border: OutlineInputBorder()),
                child: Text(DateFormat('dd/MM/yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in ExpenseCategory.values)
                  ChoiceChip(
                    avatar: Icon(c.icon, size: 16, color: c.color),
                    label: Text(c.label),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(
                  labelText: 'Note (optional)', border: OutlineInputBorder()),
            ),
            if (_raw.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Raw OCR text'),
                children: [SelectableText(_raw)],
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _scanning ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_editing ? 'Update' : 'Save expense'),
            ),
          ],
        ),
      ),
    );
  }
}
