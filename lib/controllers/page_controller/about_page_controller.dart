import 'package:flutter/material.dart'; // برای AnimationController و Offset
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart'; // پکیج برای باز کردن لینک‌ها و ایمیل

class AboutController extends GetxController with GetSingleTickerProviderStateMixin {
  /// کنترلر صفحه درباره برنامه.
  /// شامل اطلاعات توسعه‌دهنده و توابع برای تعامل با لینک‌ها و ایمیل است.
  /// همچنین انیمیشن‌های ورود صفحه را مدیریت می‌کند.

  /// نسخه فعلی برنامه
  final String appVersion = '1.0.0';

  /// نام توسعه‌دهنده برنامه
  final String developerName = 'محسن فرجی';

  /// ایمیل توسعه‌دهنده برای تماس
  final String developerEmail = 'mohsen.faraji.dev@gmail.com';

  /// وب‌سایت یا پورتفولیوی توسعه‌دهنده
  final String appLink = 'myket://details?id=com.gmail.farajiMohsen.daily_work'; // ادرس اپ در مایکت
  /// وب‌سایت یا پورتفولیوی توسعه‌دهنده
  final String otherApps = 'myket://developer/com.gmail.farajiMohsen.service_car'; // برنامه های دیگر در مایکت

  // --- کنترلرهای انیمیشن ---
  late AnimationController animationController;
  late Animation<Offset> slideAnimation;
  late Animation<double> fadeAnimation;

  @override
  void onInit() {
    super.onInit();
    // مقداردهی اولیه کنترلر انیمیشن
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // مدت زمان کلی انیمیشن
    );

    // انیمیشن Fade-in برای محتوای کلی
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut), // محو شدن طی 80% اول زمان
      ),
    );

    // انیمیشن Slide-in برای محتوای اصلی
    slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.2), // شروع کمی پایین‌تر از موقعیت نهایی
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animationController,
            curve: const Interval(
              0.2,
              1.0,
              curve: Curves.easeOutCubic,
            ), // اسلاید شدن طی 80% پایانی زمان با تاخیر
          ),
        );

    // شروع انیمیشن هنگام مقداردهی اولیه کنترلر
    animationController.forward();
  }

  @override
  void onClose() {
    animationController.dispose(); // آزاد کردن منابع کنترلر انیمیشن
    super.onClose();
  }

  /// تابع ارسال ایمیل به توسعه‌دهنده.
  /// با استفاده از `url_launcher` کلاینت ایمیل را باز می‌کند.
  // void sendEmail() async {
  //   final Uri emailLaunchUri = Uri(
  //     scheme: 'mailto',
  //     path: developerEmail,
  //     queryParameters: {'subject': 'بازخورد درباره برنامه روز کار  '},
  //   );
  //   if (await canLaunchUrl(emailLaunchUri)) {
  //     await launchUrl(emailLaunchUri);
  //   } else {
  //     Get.snackbar(
  //       'خطا',
  //       'امکان ارسال ایمیل وجود ندارد. لطفا آدرس ایمیل را کپی کنید.',
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: Colors.red.withOpacity(0.8),
  //       colorText: Colors.white,
  //     );
  //   }
  // }

  /// تابع باز کردن وب‌سایت توسعه‌دهنده.
  /// با استفاده از `url_launcher` مرورگر را باز می‌کند.
  void launchWebsite({required String link}) async {
    final Uri url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'خطا',
        'اپلیکیشن مایکت پیدا نشد',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }
}
