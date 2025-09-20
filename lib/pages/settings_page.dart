import 'package:daily_work/utils/price_format.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/wage_controller.dart';
import '../models/wage_settings.dart';
import '../utils/formater.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final WageController wageController = Get.find<WageController>();

  late bool isDaily;
  final TextEditingController dailyCtrl = TextEditingController();
  final TextEditingController hourlyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = wageController.settings.value;
    isDaily = s.isDaily;
    dailyCtrl.text = s.dailyWage.toPriceString();
    hourlyCtrl.text = s.hourlyWage.toPriceString();
  }

  @override
  void dispose() {
    dailyCtrl.dispose();
    hourlyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات دستمزد'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.settings, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'حالت محاسبه',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('روزانه'),
                          icon: Icon(Icons.calendar_today),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('ساعتی'),
                          icon: Icon(Icons.access_time),
                        ),
                      ],
                      selected: {isDaily},
                      onSelectionChanged: (set) {
                        // setState(() => isDaily = set.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.attach_money, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'مقادیر دستمزد',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dailyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'دستمزد روزانه (تومان)',
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        // Use the custom formatter here
                        ThousandSeparatorInputFormatter(),
                      ],
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      readOnly: true,

                      // controller: hourlyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'دستمزد ساعتی (تومان)',
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        // Use the custom formatter here
                        ThousandSeparatorInputFormatter(),
                      ],
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('ذخیره تنظیمات'),
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    final int daily =
        int.tryParse(dailyCtrl.text.trim().replaceAll(',', '')) ?? 0;
    final int hourly =
        int.tryParse(hourlyCtrl.text.trim().replaceAll(',', '')) ?? 0;
    final newSettings = WageSettings(
      isDaily: isDaily,
      dailyWage: daily,
      hourlyWage: hourly,
    );
    await wageController.saveSettings(newSettings);
    if (mounted) {
      Get.back(result: 1);
      Get.snackbar(
        'موفق',
        'تنظیمات ذخیره شد',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
      );
      // Get.back();
    }
  }
}
