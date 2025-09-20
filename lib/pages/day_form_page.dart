import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shamsi_date/shamsi_date.dart' as sh;
// removed unused persian_datetime_picker import
import 'package:daily_work/utils/jalali_utils.dart';

import '../controllers/wage_controller.dart';
import '../controllers/workdays_controller.dart';
import '../controllers/employers_controller.dart';
import '../models/work_day.dart';
import '../utils/formater.dart';
import '../utils/price_format.dart';

class DayFormPage extends StatefulWidget {
  final sh.Jalali selectedDate;

  const DayFormPage({super.key, required this.selectedDate});

  @override
  State<DayFormPage> createState() => _DayFormPageState();
}

class _DayFormPageState extends State<DayFormPage> {
  final WorkDaysController workDaysController = Get.find<WorkDaysController>();
  final EmployersController employersController =
      Get.find<EmployersController>();
  final WageController wageController = Get.find<WageController>();
  String? _employerErrorText;
  String? _wageErrorText;
  late WorkDay? existingWorkDay;
  int? selectedEmployerId;
  bool worked = false;
  double hours = 8.0;
  String workType = 'full'; // 'full' = یک روز, 'half' = نصف روز
  final TextEditingController wageTextController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    existingWorkDay = workDaysController.getByJalali(widget.selectedDate);
    if (existingWorkDay != null) {
      selectedEmployerId = existingWorkDay!.employerId;
      worked = existingWorkDay!.worked;
      hours = existingWorkDay!.hours;
      workType = hours == 8.0 ? 'full' : 'half';
      descriptionController.text = existingWorkDay!.description ?? '';
      wageTextController.text = existingWorkDay!.wage != null
          ? existingWorkDay!.wage!.toString().toPriceString()
          : '';
    } else {
      if (wageController.settings.value.dailyWage != 0) {
        wageTextController.text = wageController.settings.value.dailyWage
            .toPriceString();
      } else {
        wageTextController.text = '1000000'.toPriceString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jd = widget.selectedDate;

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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed('/settings')!.then((value) {
              if (value == 1 && existingWorkDay == null) {
                wageTextController.text = wageController
                    .settings
                    .value
                    .dailyWage
                    .toPriceString();
              }
            }),
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

                                    decoration: InputDecoration(
                                      labelText: 'انتخاب کارفرما',
                                      border: const OutlineInputBorder(),
                                      errorText: _employerErrorText,
                                    ),
                                    hint: const Text('کارفرما را انتخاب کنید'),
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
                                        if (value != null) {
                                          _employerErrorText = null;
                                        }
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
                                        'مبلغ دستمزد *',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: wageTextController,
                                    decoration: InputDecoration(
                                      labelText: 'مبلغ دستمزد (تومان)',
                                      border: const OutlineInputBorder(),
                                      errorText: _wageErrorText,
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      // Use the custom formatter here
                                      ThousandSeparatorInputFormatter(),
                                    ],
                                    onChanged: (value) {
                                      // با هر تغییر، سعی کن خطا را پاک کنی (اعتبارسنجی اصلی در ذخیره است)
                                      if (value.isNotEmpty &&
                                          _wageErrorText != null) {
                                        setState(() {
                                          _wageErrorText = null;
                                        });
                                      }
                                    },
                                    //
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

  @override
  void dispose() {
    wageTextController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _saveWorkDay() {
    // بازنشانی پیام های خطا قبل از هر اعتبارسنجی
    setState(() {
      _employerErrorText = null;
      _wageErrorText = null;
    });

    bool isValid = true;

    // 1. اعتبارسنجی انتخاب کارفرما (فقط اگر کار کرده باشد)
    if (worked && selectedEmployerId == null) {
      setState(() {
        _employerErrorText = 'لطفا یک کارفرما انتخاب کنید';
      });
      isValid = false;
    }

    // 2. اعتبارسنجی وارد کردن مبلغ دستمزد (فقط اگر کار کرده باشد)
    final String wageInput = wageTextController.text.replaceAll(',', '').trim();
    if (worked && wageInput.isEmpty) {
      setState(() {
        _wageErrorText = 'لطفا مبلغ دستمزد را وارد کنید';
      });
      isValid = false;
    }

    final int? wageValue = wageInput.isEmpty ? null : int.tryParse(wageInput);
    if (worked && wageInput.isNotEmpty && wageValue == null) {
      // اگر چیزی وارد شده اما قابل تبدیل به عدد نیست (مثلا فقط حروف)
      // ThousandSeparatorInputFormatter باید از این جلوگیری کند، اما برای اطمینان
      setState(() {
        _wageErrorText = 'مبلغ دستمزد نامعتبر است';
      });
      isValid = false;
    }
    // همچنین می‌توانید برای wageValue <= 0 هم خطا در نظر بگیرید اگر منطقی باشد
    // if (worked && wageValue != null && wageValue <= 0) {
    //   setState(() {
    //     _wageErrorText = 'مبلغ دستمزد باید بیشتر از صفر باشد';
    //   });
    //   isValid = false;
    // }

    // اگر اعتبارسنجی موفقیت آمیز نبود، از ادامه کار جلوگیری کن
    if (!isValid) {
      return;
    }

    // اگر `worked` نباشد، `employerId` و `wage` می‌توانند null باشند یا مقدار پیش‌فرض بگیرند
    final jalaliDate = JalaliUtils.formatFromJalali(widget.selectedDate);
    final workDay = WorkDay(
      jalaliDate: jalaliDate,
      employerId: worked ? selectedEmployerId : null,
      // اگر کار نکرده، کارفرما مهم نیست
      worked: worked,
      hours: worked ? hours : 0,
      wage: worked ? wageValue : null,
      // اگر کار نکرده، دستمزد صفر یا null است
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
    );
    print('tarikh (Jalali)==$jalaliDate');
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
              workDaysController.deleteByJalali(widget.selectedDate);
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
