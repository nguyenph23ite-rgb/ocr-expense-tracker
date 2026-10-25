import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/expense_store.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN');
  await initializeDateFormatting('en_US');
  final store = ExpenseStore();
  await store.load();
  runApp(ExpenseApp(store: store));
}

class ExpenseApp extends StatelessWidget {
  final ExpenseStore store;
  const ExpenseApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2BB673),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF2BB673),
      ),
      home: HomeScreen(store: store),
    );
  }
}
