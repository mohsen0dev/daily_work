import 'package:daily_work/controllers/setting_controller.dart';
import 'package:daily_work/utils/price_format.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import '../controllers/payments_controller.dart';
import '../controllers/workdays_controller.dart';
import '../utils/jalali_utils.dart';
import 'day_form_page.dart';

/// صفحه نمایش تقویم شمسی.
/// این صفحه روزهای کاری را با رنگ‌های مختلف نمایش می‌دهد و امکان انتخاب ماه و روز را فراهم می‌کند.
class CalendarPage extends StatefulWidget {
  /// سازنده CalendarPage.
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

/// State مربوط به ویجت CalendarPage.
class _CalendarPageState extends State<CalendarPage> {
  /// کنترلر روزهای کاری که از GetX دریافت می‌شود.
  /// (Use the existing singleton instance registered in main.dart)
  final WorkDaysController workDaysController = Get.find<WorkDaysController>();
  final PaymentsController paymentsController = Get.find<PaymentsController>();
  final SettingController settingCtrl = Get.find<SettingController>();

  /// تاریخ جلالی فوکوس شده فعلی در تقویم.
  Jalali _focusedJalali = Jalali.now();

  /// روز انتخاب شده توسط کاربر در ماه فعلی.
  final RxInt _selectedDay = Jalali.now().day.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_focusedJalali.formatter.mN} ${_focusedJalali.year}'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            // Update the state and inform GetX about the change.
            setState(() {
              _focusedJalali = Jalali.now();
              _selectedDay.value = _focusedJalali.day;
            });
            // Calling update() to refresh the data in controller.
            workDaysController.update();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedJalali = _focusedJalali.addMonths(-1);
                _selectedDay.value = 1; // تنظیم روز به اول ماه هنگام تغییر ماه
              });
              // Calling update() to refresh the data in controller.
              workDaysController.update();
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedJalali = _focusedJalali.addMonths(1);
                _selectedDay.value = 1; // تنظیم روز به اول ماه هنگام تغییر ماه
              });
              // Calling update() to refresh the data in controller.
              workDaysController.update();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed('/settings'),
          ),
        ],
      ),
      // Use Obx to rebuild the widget when any Rx variable changes.
      body: SingleChildScrollView(
        child: Obx(() {
          final monthLength = _focusedJalali.monthLength;
          final firstWeekDay = Jalali(
            _focusedJalali.year,
            _focusedJalali.month,
            1,
          ).weekDay;
          final today = Jalali.now();
          final List<Widget> dayWidgets =
              []; // استفاده از const در صورت امکان برای محتویات

          // اضافه کردن فضاهای خالی برای روزهای اول هفته که در ماه قبل هستند
          for (int i = 1; i < firstWeekDay; i++) {
            dayWidgets.add(const SizedBox());
          }

          // اضافه کردن ویجت برای هر روز ماه
          for (int day = 1; day <= monthLength; day++) {
            final jd = Jalali(_focusedJalali.year, _focusedJalali.month, day);
            final wd = workDaysController.getByJalali(jd);
            final bool worked = wd?.worked == true;
            final bool isToday =
                (jd.year == today.year &&
                jd.month == today.month &&
                jd.day == today.day);
            final bool isSelected = day == _selectedDay.value;

            dayWidgets.add(
              GestureDetector(
                onTap: () async {
                  _selectedDay.value = day;
                  // Navigate and wait for the result.
                  await Get.to(() => DayFormPage(selectedDate: jd));
                  // After returning from DayFormPage, force a data refresh.
                  workDaysController.update();
                },
                child: _DayCell(
                  jd: jd,
                  worked: worked,
                  isToday: isToday,
                  isSelected: isSelected,
                ),
              ),
            );
          }
          // فیلتر کردن روزهای کاری ماه جاری
          final currentMonthWorkdays = workDaysController.workdays.values.where(
            (wd) {
              final workdayJalali = JalaliUtils.parseJalali(wd.jalaliDate);
              return workdayJalali.year == _focusedJalali.year &&
                  workdayJalali.month == _focusedJalali.month;
            },
          ).toList();

          // محاسبه تعداد روزهای کارکرد (بر اساس مجموع ساعات تقسیم بر 8)
          final double workedDaysCount = currentMonthWorkdays
              .where((wd) => wd.worked)
              .fold<double>(0, (sum, wd) => sum + (wd.hours / 8.0));
          final String formattedWorkedDays = workedDaysCount % 1 == 0
              ? workedDaysCount.toInt().toString()
              : workedDaysCount.toStringAsFixed(1);

          // محاسبه مجموع دستمزد ماه جاری
          final int totalWageForMonth = currentMonthWorkdays.fold<int>(
            0,
            (sum, wd) => sum + (wd.wage ?? 0),
          );
          final String formattedWage = totalWageForMonth.toPriceString();

          final currentMonthPayments = paymentsController.payments.where((p) {
            final paymentJalali = JalaliUtils.parseJalali(
              p.value.jalaliDate,
            ); // p.value
            return paymentJalali.year == _focusedJalali.year &&
                paymentJalali.month == _focusedJalali.month;
          }).toList();

          // محاسبه مجموع دریافتی ماه جاری
          final int totalPaymentsForMonth = currentMonthPayments.fold<int>(
            0,
            (sum, p) => sum + p.value.amount,
          );
          final String formattedPayments = totalPaymentsForMonth
              .toPriceString();
          // ---------- پایان منطق محاسبات برای خلاصه ماه ----------

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Row(
                    // استفاده از const
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('ش'),
                      Text('ی'),
                      Text('د'),
                      Text('س'),
                      Text('چ'),
                      Text('پ'),
                      Text('ج', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 8), // استفاده از const
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    children: dayWidgets,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    // width: MediaQuery.of(context).size.width-32,
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: 10,
                      horizontal: 40,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withAlpha(100),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NoteWorks(
                          title: 'تعداد روزهای کارکرد',
                          value: formattedWorkedDays,
                          numberic: false,
                        ),

                        NoteWorks(
                          title: 'مجموع دستمزد ماه جاری',
                          value: formattedWage,
                          numberic: true,
                        ),
                        NoteWorks(
                          title: 'مجموع دریافتی ماه جاری',
                          value: formattedPayments,
                          numberic: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// ویجت نمایش دهنده خلاصه‌ای از آمار ماهانه (مثلاً تعداد روزهای کاری، دستمزد
class NoteWorks extends StatelessWidget {
  const NoteWorks({
    super.key,
    required this.title,
    required this.value,
    this.numberic = false,
  });

  final String title;
  final String value;
  final bool numberic;

  @override
  Widget build(BuildContext context) {
    String endText = numberic ? 'تومان' : 'روز';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text('$title: $value $endText'),
    );
  }
}

/// ویجت نمایش دهنده یک سلول (روز) در تقویم.
class _DayCell extends StatelessWidget {
  /// تاریخ جلالی مربوط به این سلول.
  final Jalali jd;

  /// وضعیت کار شده بودن روز (آیا کار در این روز ثبت شده است).
  final bool worked;

  /// آیا این روز، روز جاری است.
  final bool isToday;

  /// آیا این روز، روز انتخاب شده توسط کاربر است.
  final bool isSelected;

  /// سازنده _DayCell.
  const _DayCell({
    required this.jd,
    required this.worked,
    required this.isToday,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = Get.theme.textTheme.bodyMedium!.color!;
    Color bg;
    if (worked) {
      bg = Colors.blue.shade100;
    } else {
      bg = Colors.transparent;
    }
    final bool isFriday = jd.weekDay == 7;
    if (isFriday) {
      textColor = Colors.red; // جمعه قرمز
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 1.0, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? Colors.red
                : worked
                ? Colors.blue
                : Colors.grey.shade300, // استفاده از !
            width: isToday ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '${jd.day}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: worked ? Colors.blue.shade900 : textColor, // استفاده از !
            fontSize: worked ? 16 : 14,
          ),
        ),
      ),
    );
  }
}
