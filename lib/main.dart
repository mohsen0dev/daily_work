import 'package:daily_work/controllers/employers_controller.dart';
import 'package:daily_work/controllers/payments_controller.dart';
import 'package:daily_work/controllers/wage_controller.dart';
import 'package:daily_work/controllers/workdays_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/employer.dart';
import 'models/payment.dart';
import 'models/wage_settings.dart';
import 'models/work_day.dart';
import 'pages/calendar_page.dart';
import 'pages/employers_page.dart';
import 'pages/payments_page.dart';
import 'pages/balance_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Register adapters
  Hive
    ..registerAdapter(EmployerAdapter())
    ..registerAdapter(WorkDayAdapter())
    ..registerAdapter(PaymentAdapter())
    ..registerAdapter(WageSettingsAdapter());

  // Open boxes
  await Future.wait([
    Hive.openBox<Employer>('employers'),
    Hive.openBox<WorkDay>('workdays'),
    Hive.openBox<Payment>('payments'),
    Hive.openBox<WageSettings>('settings'),
  ]);
  Get.put(WorkDaysController());
  Get.put(EmployersController());
  Get.put(PaymentsController());
  Get.put(WageController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      textDirection: TextDirection.rtl,
      title: 'Daily Work',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CalendarPage(),
    const EmployersPage(),
    const PaymentsPage(),
    const BalancePage(),
  ];

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: isSelected ? 1.2 : 1.0),
              curve: Curves.easeInOut,
              duration: const Duration(milliseconds: 200),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                );
              },
            ),
            const SizedBox(height: 1),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        // height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.calendar_month, 'تقویم'),
                _buildNavItem(1, Icons.business, 'کارفرما'),
                _buildNavItem(2, Icons.payments, 'دریافتی‌'),
                _buildNavItem(3, Icons.account_balance_wallet, 'خلاصه مالی'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
