import 'package:daily_work/controllers/employers_controller.dart';
import 'package:daily_work/controllers/payments_controller.dart';
import 'package:daily_work/controllers/setting_controller.dart';
import 'package:daily_work/controllers/workdays_controller.dart';
import 'package:daily_work/utils/back_button_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'models/employer.dart';
import 'models/payment.dart';
import 'models/settings.dart';
import 'models/work_day.dart';
import 'pages/calendar_page.dart';
import 'pages/employers_page.dart';
import 'pages/payments_page.dart';
import 'pages/balance_page.dart';
import 'pages/charts_page.dart';
import 'pages/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Register adapters
  Hive
    ..registerAdapter(EmployerModelAdapter())
    ..registerAdapter(WorkDayModelAdapter())
    ..registerAdapter(PaymentModelAdapter())
    ..registerAdapter(SettingsModelAdapter());

  // Open all boxes

  await Hive.openBox<EmployerModel>('employers');
  await Hive.openBox<WorkDayModel>('workdays');
  await Hive.openBox<PaymentModel>('payments');
  await Hive.openBox<SettingsModel>('settings');

  Get.put<SettingController>(
    SettingController(), // Pass the opened box
    permanent: true,
  );
  await Get.putAsync<WorkDaysController>(() async {
    final controller = WorkDaysController();
    await controller.init();
    return controller;
  }, permanent: true);

  Get.put(EmployersController());
  Get.put(PaymentsController());
  Get.put(SettingController());
  Get.put(MainNavigationController());

  runApp(const MyApp());
}

// ... (existing imports)

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final SettingController settingController = Get.find<SettingController>();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      textDirection: TextDirection.rtl,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        // Add Localization
        PersianMaterialLocalizations.delegate,
        PersianCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Daily Work',

      themeMode: settingController.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'yekan', // <<< Light theme font set correctly here
        scaffoldBackgroundColor: const Color(0xeeffFfff),

        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          primary: Colors.blue,
          onPrimary: Colors.black87,
          secondary: Colors.orangeAccent,
          onSecondary: Colors.white,
          error: Colors.redAccent,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black87,
          seedColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        // <<< CHANGE: Create a new ThemeData for dark theme
        useMaterial3: true,
        fontFamily: 'yekan', // Correctly set for dark theme
        brightness: Brightness.dark, // Essential for dark theme behavior
        primaryColor: Colors.tealAccent, // Your desired dark primary color
        scaffoldBackgroundColor: Colors.grey[900], // Your desired dark background color
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark, // Essential for dark mode color scheme
          primary: Colors.tealAccent,
          onPrimary: Colors.black,
          secondary: Colors.deepOrangeAccent,
          onSecondary: Colors.white,
          error: Colors.redAccent,
          onError: Colors.black,
          surface: Colors.grey[900]!,
          onSurface: Colors.white70,
          seedColor: Colors.tealAccent,
        ),
        // Add other dark theme properties here as needed
        // For example, if you want specific text themes for dark mode:
        // textTheme: const TextTheme(
        //   bodyMedium: TextStyle(color: Colors.white70, fontFamily: 'sans'),
        //   // etc.
        // ),
      ),

      // darkTheme: ThemeData(useMaterial3: true, fontFamily: 'vazir').copyWith(
      //   // The `fontFamily` parameter should be passed to `copyWith` directly,
      //   // as `ThemeData.dark()` itself does not have a `fontFamily` parameter.
      //   // <<< Dark theme font set correctly here
      //   brightness: Brightness.dark,
      //   primaryColor: Colors.tealAccent,
      //   scaffoldBackgroundColor: Colors.grey[900],
      //   colorScheme: ColorScheme.fromSeed(
      //     brightness: Brightness.dark,
      //     primary: Colors.tealAccent,
      //     onPrimary: Colors.black,
      //     secondary: Colors.deepOrangeAccent,
      //     onSecondary: Colors.white,
      //     error: Colors.redAccent,
      //     onError: Colors.black,
      //     surface: Colors.grey[900]!,
      //     onSurface: Colors.white70,
      //     seedColor: Colors.tealAccent,
      //   ),
      // ),
      home: const MainNavigationPage(),
      getPages: [GetPage(name: '/settings', page: SettingsPage.new)],
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late final MainNavigationController _navigationController;

  final List<Widget> _pages = [
    const CalendarPage(),
    const EmployersPage(),
    const PaymentsPage(),
    const BalancePage(),
    const ChartsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _navigationController = Get.find<MainNavigationController>();
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    return Obx(() {
      final isSelected = _navigationController.currentIndex == index;
      return GestureDetector(
        onTap: () => _navigationController.setCurrentIndex(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
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
                    child: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          BackButtonHandler.handleBackButton(context, _navigationController.currentIndex);
        }
      },
      // onPopInvoked: (didPop) {
      //   if (!didPop) {
      //     BackButtonHandler.handleBackButton(context, _navigationController.currentIndex);
      //   }
      // },
      child: Obx(
        () => Scaffold(
          body: _pages[_navigationController.currentIndex],
          bottomNavigationBar: Container(
            // height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(color: Theme.of(context).dividerColor, blurRadius: 10, offset: const Offset(0, 4)),
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
                    _buildNavItem(4, Icons.bar_chart, 'نمودارها'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
