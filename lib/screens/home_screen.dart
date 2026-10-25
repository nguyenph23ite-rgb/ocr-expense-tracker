import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/expense_store.dart';
import '../models/expense.dart';
import '../widgets/donut_chart.dart';
import '../widgets/weekly_bar_chart.dart';
import 'capture_screen.dart';
import 'review_screen.dart';

class HomeScreen extends StatelessWidget {
  final ExpenseStore store;
  const HomeScreen({super.key, required this.store});

  static final _money = NumberFormat.decimalPattern('vi_VN');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expense Tracker'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.pie_chart), text: 'Insights'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Transactions'),
          ]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CaptureScreen(store: store)),
          ),
          icon: const Icon(Icons.document_scanner),
          label: const Text('Scan'),
        ),
        body: ListenableBuilder(
          listenable: store,
          builder: (context, _) => TabBarView(children: [
            _insights(context),
            _list(context),
          ]),
        ),
      ),
    );
  }

  Widget _insights(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1);
    final cats = store.totalsByCategory(from: monthStart, to: monthEnd);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text('This month (${DateFormat('MMMM yyyy').format(now)})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DonutChart(data: cats),
          ),
        ),
        const SizedBox(height: 20),
        Text('Last 7 days', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: WeeklyBarChart(data: store.last7Days()),
          ),
        ),
      ],
    );
  }

  Widget _list(BuildContext context) {
    if (store.expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No expenses yet. Tap Scan to add your first receipt.',
              textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: store.expenses.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final e = store.expenses[i];
        return Dismissible(
          key: ValueKey(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => store.remove(e),
          child: ListTile(
            leading: e.thumbnailPath != null &&
                    File(e.thumbnailPath!).existsSync()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(e.thumbnailPath!),
                        width: 48, height: 48, fit: BoxFit.cover),
                  )
                : CircleAvatar(
                    backgroundColor: e.category.color.withValues(alpha: 0.15),
                    child: Icon(e.category.icon, color: e.category.color),
                  ),
            title: Text(e.merchant),
            subtitle: Text(
                '${e.category.label} · ${DateFormat('dd/MM/yyyy').format(e.date)}'),
            trailing: Text('${_money.format(e.amountVnd)} đ',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ReviewScreen(store: store, expense: e)),
            ),
          ),
        );
      },
    );
  }
}
