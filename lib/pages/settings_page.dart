import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/page_controller/about_page_controller.dart';
import '../controllers/setting_controller.dart';
import '../services/backup_restore_service.dart';
import '../utils/formater.dart'; // برای ThousandSeparatorInputFormatter

/// صفحه تنظیمات
/// این صفحه به کاربر امکان می‌دهد تنظیمات مختلف برنامه مانند تم،
/// مقادیر دستمزد و کارفرمای پیش‌فرض را مدیریت کند.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // تزریق کنترلر صفحه تنظیمات
    final SettingsController controllerSeting = Get.put(SettingsController());
    Get.put(BackupRestoreService());

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات'), centerTitle: true),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controllerSeting.saveSettings2();
        },
        backgroundColor: Theme.of(context).primaryColor,

        label: SizedBox(
          width: MediaQuery.sizeOf(context).width - 90,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save, color: Colors.black87),
              SizedBox(width: 5),
              Text(
                'ذخیره تنظیمات',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ویجت برای تنظیمات تم (روشن/تاریک)
            _CartWidget(
              title: 'ظاهر روشن / تاریک',
              icon: const Row(
                children: <Widget>[Icon(Icons.dark_mode), Text('/'), Icon(Icons.light_mode_outlined)],
              ),
              child: Obx(() {
                return SwitchListTile(
                  title: Text(controllerSeting.isDarkMode ? 'تیره' : 'روشن'),
                  value: controllerSeting.isDarkMode,
                  onChanged: (bool value) {
                    controllerSeting.switchTheme(value);
                  },
                  activeTrackColor: Colors.blueGrey,
                  activeThumbColor: Colors.tealAccent,
                  inactiveThumbColor: Colors.blue,
                );
              }),
            ),
            const SizedBox(height: 16.0),

            // ویجت برای مقادیر دستمزد
            Obx(() {
              return _CartWidget(
                title: 'مقادیر دستمزد',
                icon: const Icon(Icons.attach_money, color: Colors.green),
                child: TextField(
                  key: ValueKey(controllerSeting.dailyWage.value), // **تغییر کلیدی:** برای اطمینان از rebuild
                  // **تغییر مهم:** استفاده از .value برای دسترسی به TextEditingController واقعی
                  controller: controllerSeting.dailyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'دستمزد روزانه (تومان)',
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: <ThousandSeparatorInputFormatter>[ThousandSeparatorInputFormatter()],
                  keyboardType: TextInputType.number,
                ),
              );
            }),

            const SizedBox(height: 16.0),

            // ویجت برای انتخاب کارفرمای پیش‌فرض
            _CartWidget(
              title: 'کارفرمای پیش فرض',
              icon: const Icon(Icons.person_search, color: Colors.blue),
              child: Obx(() {
                return DropdownButtonFormField<int?>(
                  initialValue: controllerSeting.selectedEmployerId.value, // مقدار جاری از کنترلر
                  decoration: const InputDecoration(
                    labelText: 'انتخاب کارفرمای پیش فرض',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('کارفرمای پیش‌فرض را انتخاب کنید'),
                  items: <DropdownMenuItem<int?>>[
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('انتخاب نشده (هنگام ثبت انتخاب شود)'),
                    ),

                    // ساخت لیست DropdownMenuItem از لیست کارفرمایان موجود
                    ...controllerSeting.employersController.employers.map((entry) {
                      //   // فرض بر اینکه value از نوع EmployerModel است
                      return DropdownMenuItem<int?>(value: entry.key, child: Text(entry.value.name));
                    }),
                  ],
                  onChanged: (int? value) {
                    controllerSeting.setSelectedEmployer(value); // به‌روزرسانی در کنترلر
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            _CartWidget(
              title: 'پشتیبان گیری و بازیابی',
              icon: const Icon(Icons.backup_outlined),
              child: Row(
                children: [
                  Expanded(
                    child:
                        // اتصال دکمه پشتیبان‌گیری به متد کنترلر
                        ElevatedButton.icon(
                          onPressed: controllerSeting.backupData,
                          icon: const Icon(Icons.save_alt_outlined),
                          label: const Text('پشتیبان‌گیری'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ),
                  ),

                  const SizedBox(width: 16.0),
                  Expanded(
                    child:
                        // اتصال دکمه بازیابی به متد کنترلر
                        ElevatedButton.icon(
                          onPressed: controllerSeting.restoreData,
                          icon: const Icon(Icons.restore_outlined),
                          label: const Text('بازیابی اطلاعات'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CartWidget(
              title: ' درباره برنامه',
              icon: const Icon(Icons.info_outline),
              child: Center(
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width - 100,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.email),
                    onPressed: () {
                      Get.lazyPut(() => AboutController());
                      Get.toNamed('/about'); // ناوبری به صفحه AboutPage
                    },
                    label: const Text('درباره برنامه'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

/// ویجت کارت عمومی برای نمایش یک بخش از تنظیمات.
/// شامل یک عنوان، آیکون و محتوای سفارشی.
class _CartWidget extends StatelessWidget {
  const _CartWidget({required this.title, required this.icon, required this.child});

  final String title;
  final Widget icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                icon,
                const SizedBox(width: 8.0),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12.0),
            child,
          ],
        ),
      ),
    );
  }
}
