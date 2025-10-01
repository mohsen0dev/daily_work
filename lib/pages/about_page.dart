import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/page_controller/about_page_controller.dart';

class AboutPage extends GetView<AboutController> {
  /// صفحه درباره سازنده برنامه.
  /// این صفحه اطلاعاتی درباره توسعه‌دهنده و نسخه برنامه را نمایش می‌دهد
  /// و امکان تماس یا بازدید از وب‌سایت را فراهم می‌کند.
  /// طراحی مدرن و دارای انیمیشن‌های ورود است.
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('درباره برنامه'), centerTitle: true),
      body: FadeTransition(
        // انیمیشن محو شدن کلی برای بدنه صفحه
        opacity: controller.fadeAnimation,
        child: SlideTransition(
          // انیمیشن اسلاید شدن کلی برای بدنه صفحه
          position: controller.slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0, // افزایش فضای خالی برای زیبایی
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // === بخش لوگو و نام برنامه ===
                _buildAppHeader(context),
                const SizedBox(height: 12),

                // === بخش درباره برنامه (توضیحات کلی) ===
                _buildAppDescription(context),
                const SizedBox(height: 15),

                // === بخش اطلاعات توسعه‌دهنده و راه‌های تماس ===
                _buildDeveloperInfo(
                  context,
                  controller, // ارسال کنترلر برای دسترسی به متدهای تماس
                ),
                const SizedBox(height: 15),

                // === بخش کپی‌رایت ===
                _buildCopyright(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ویجت هدر برنامه شامل آیکون، نام و نسخه.
  Widget _buildAppHeader(BuildContext context) {
    return Column(
      children: <Widget>[
        Card(
          elevation: 8.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/images/icon.png', height: 100),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'روز کار',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text('نسخه: ${controller.appVersion}', style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  /// ویجت توضیحات کوتاه برنامه.
  /// شامل نام کامل برنامه و توضیحات کلی عملکرد آن.
  Widget _buildAppDescription(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Text(
              'اپلیکیشن مدیریت کارهای روزانه',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'این برنامه برای کمک به شما در مدیریت کارها، کارفرماها و امور مالی روزانه طراحی شده است. '
              'با استفاده از این اپلیکیشن، می‌توانید به سادگی فعالیت‌های کاری خود را ثبت، پیگیری و گزارش‌گیری کنید تا سازماندهی و کنترل بیشتری بر وظایف و درآمد خود داشته باشید.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  /// ویجت اطلاعات توسعه‌دهنده و راه‌های ارتباطی.
  /// شامل نام توسعه‌دهنده، دکمه ارسال ایمیل و دکمه بازدید از وب‌سایت.
  Widget _buildDeveloperInfo(BuildContext context, AboutController controller) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'توسعه‌دهنده',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: <Widget>[
                const Icon(Icons.person_outline, color: Colors.grey),
                const SizedBox(width: 10),
                Text(controller.developerName, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: 20),
            // دکمه تماس با ایمیل
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.email),
                label: const Text('ارسال ایمیل'),
                onPressed: controller.sendEmail,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // دکمه بازدید از وب‌سایت
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.star_outline_rounded),
                label: const Text('امتیاز به برنامه'),
                onPressed: () {
                  controller.launchWebsite(link: controller.appLink);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // دکمه بازدید از وب‌سایت
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.store),
                label: const Text('برنامه های دیگر من'),
                onPressed: () {
                  controller.launchWebsite(link: controller.otherApps);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ویجت نمایش کپی‌رایت.
  Widget _buildCopyright(BuildContext context) {
    return Text(
      'کلیه حقوق این اپلیکیشن محفوظ است © ${DateTime.now().year}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
      textAlign: TextAlign.center,
    );
  }
}
