import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../controllers/workdays_controller.dart';
import '../controllers/employers_controller.dart';
import '../models/work_day.dart';
import '../utils/price_format.dart';

class DayFormPage extends StatefulWidget {
  final DateTime selectedDate;

  const DayFormPage({super.key, required this.selectedDate});

  @override
  State<DayFormPage> createState() => _DayFormPageState();
}

class _DayFormPageState extends State<DayFormPage> {
  final WorkDaysController workDaysController = Get.put(WorkDaysController());
  final EmployersController employersController = Get.put(
    EmployersController(),
  );

  late WorkDay? existingWorkDay;
  int? selectedEmployerId;
  bool worked = false;
  double hours = 8.0;
  String workType = 'full'; // 'full' = یک روز, 'half' = نصف روز
  final TextEditingController wageController = TextEditingController(
    text: '1000000'.toPriceString(),
  );
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    existingWorkDay = workDaysController.getByDate(widget.selectedDate);
    if (existingWorkDay != null) {
      selectedEmployerId = existingWorkDay!.employerId;
      worked = existingWorkDay!.worked;
      hours = existingWorkDay!.hours;
      workType = hours == 8.0 ? 'full' : 'half';
      descriptionController.text = existingWorkDay!.description ?? '';
      wageController.text = existingWorkDay!.wage != null
          ? existingWorkDay!.wage!.toString().toPriceString()
          : '1000000'.toPriceString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final jd = Jalali.fromDateTime(widget.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('${jd.day}/${jd.month}/${jd.year}'),
        centerTitle: true,
        actions: [
          if (existingWorkDay != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _showDeleteConfirmDialog,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Work Status
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 30),
                    child: child,
                  ),
                );
              },
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.work, color: Colors.orange, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'وضعیت کار',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('روز کاری'),
                        subtitle: Text(worked ? 'کار کردم' : 'کار نکردم'),
                        value: worked,
                        onChanged: (value) {
                          setState(() {
                            worked = value;
                          });
                        },
                        activeColor: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: worked
                  ? Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 30),
                                child: child,
                              ),
                            );
                          },
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.person_search,
                                        color: Colors.blue,
                                        size: 22,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'انتخاب کارفرما',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int?>(
                                    value: selectedEmployerId,
                                    decoration: const InputDecoration(
                                      labelText: 'انتخاب کارفرما',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: employersController.employers.map((
                                      entry,
                                    ) {
                                      return DropdownMenuItem<int?>(
                                        value: entry.key,
                                        child: Text(entry.value.name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedEmployerId = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.access_time,
                                        color: Colors.purple,
                                        size: 22,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'ساعت کاری',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: workType,
                                    decoration: const InputDecoration(
                                      labelText: 'ساعت کاری',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'full',
                                        child: Text('یک روز'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'half',
                                        child: Text('نصف روز'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        workType = value ?? 'full';
                                        hours = workType == 'full' ? 8.0 : 4.0;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.attach_money,
                                        color: Colors.green,
                                        size: 22,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'مبلغ دستمزد',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: wageController,
                                    decoration: const InputDecoration(
                                      labelText: 'مبلغ دستمزد (تومان)',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      String digits = value.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      );
                                      wageController.value = wageController
                                          .value
                                          .copyWith(
                                            text: digits.toPriceString(),
                                            selection: TextSelection.collapsed(
                                              offset: digits
                                                  .toPriceString()
                                                  .length,
                                            ),
                                          );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'توضیحات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'توضیحات کار انجام شده',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveWorkDay,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  existingWorkDay != null ? 'بروزرسانی' : 'ذخیره',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveWorkDay() {
    final wageValue =
        int.tryParse(wageController.text.replaceAll(',', '')) ?? 1000000;
    final workDay = WorkDay(
      date: widget.selectedDate,
      employerId: selectedEmployerId,
      worked: worked,
      hours: worked ? hours : 0,
      wage: worked ? wageValue : null,
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
    );

    workDaysController.upsertDay(workDay);
    Get.back();
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید اطلاعات این روز را حذف کنید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              workDaysController.deleteByDate(widget.selectedDate);
              Navigator.pop(context);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
