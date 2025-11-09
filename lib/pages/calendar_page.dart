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
  final WorkDaysController workDaysController = Get.find<WorkDaysController>();
  final PaymentsController paymentsController = Get.find<PaymentsController>();
  final SettingsController settingCtrl = Get.find<SettingsController>();

  /// تاریخ جلالی فوکوس شده فعلی در تقویم.
  Jalali _focusedJalali = Jalali.now();

  /// روز انتخاب شده توسط کاربر در ماه فعلی.
  final RxInt _selectedDay = Jalali.now().day.obs;

  // تابعی برای بارگذاری مجدد داده‌ها و بازسازی UI
  void _refreshCalendarData() {
    setState(() {
      _focusedJalali = _focusedJalali; // نیازی به تغییر نیست مگر اینکه بخواهیم ماه را عوض کنیم
      _selectedDay.value = _selectedDay.value; // حفظ روز انتخاب شده
    });
    // فراخوانی update برای اطمینان از اینکه کنترلر داده ها را دوباره بارگیری میکند
    workDaysController.update();
    // همچنین تنظیمات را نیز به روز رسانی میکنیم تا تم و سایر مقادیر اعمال شوند
    settingCtrl.update();
  }

  @override
  void initState() {
    super.initState();
    _refreshCalendarData(); // هنگام اولیه شدن صفحه، داده ها را بارگذاری میکنیم
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_focusedJalali.formatter.mN} ${_focusedJalali.year}'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            _refreshCalendarData(); // استفاده از تابع کمکی برای ریفرش
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
              _refreshCalendarData(); // فراخوانی برای به‌روزرسانی داده‌ها
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedJalali = _focusedJalali.addMonths(1);
                _selectedDay.value = 1; // تنظیم روز به اول ماه هنگام تغییر ماه
              });
              _refreshCalendarData(); // فراخوانی برای به‌روزرسانی داده‌ها
            },
          ),
          // دکمه تنظیمات
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // انتقال به صفحه تنظیمات
              Get.toNamed('/settings')?.then((_) {
                _refreshCalendarData();
              });
            },
          ),
        ],
      ),
      // Use Obx to rebuild the widget when any Rx variable changes.
      body: SingleChildScrollView(
        child: Obx(() {
          final monthLength = _focusedJalali.monthLength;
          final firstWeekDay = Jalali(_focusedJalali.year, _focusedJalali.month, 1).weekDay;
          final today = Jalali.now();
          final List<Widget> dayWidgets = []; // استفاده از const در صورت امکان برای محتویات

          // اضافه کردن فضاهای خالی برای روزهای اول هفته که در ماه قبل هستند
          for (int i = 1; i < firstWeekDay; i++) {
            dayWidgets.add(const SizedBox());
          }

          // اضافه کردن ویجت برای هر روز ماه
          for (int day = 1; day <= monthLength; day++) {
            final jd = Jalali(_focusedJalali.year, _focusedJalali.month, day);
            // دریافت اطلاعات روز کاری از کنترلر
            final wd = workDaysController.getByJalali(jd);
            final bool worked = wd?.worked == true;
            final bool isToday = (jd.year == today.year && jd.month == today.month && jd.day == today.day);
            final bool isSelected = day == _selectedDay.value;

            dayWidgets.add(
              GestureDetector(
                onTap: () async {
                  _selectedDay.value = day; // انتخاب روز
                  // ناوبری به صفحه فرم روز و انتظار برای نتیجه
                  await Get.to(() => DayFormPage(selectedDate: jd));
                  // پس از بازگشت از DayFormPage، داده ها را دوباره بارگذاری کن
                  _refreshCalendarData(); // به روز رسانی تقویم پس از تغییرات
                },
                child: _DayCell(jd: jd, worked: worked, isToday: isToday, isSelected: isSelected),
              ),
            );
          }

          // فیلتر کردن روزهای کاری ماه جاری برای نمایش خلاصه
          final currentMonthWorkdays = workDaysController.workdays.values.where((wd) {
            final workdayJalali = JalaliUtils.parseJalali(wd.jalaliDate);
            return workdayJalali.year == _focusedJalali.year && workdayJalali.month == _focusedJalali.month;
          }).toList();

          // محاسبه تعداد روزهای کارکرد (بر اساس مجموع ساعات تقسیم بر 8)
          final double workedDaysCount = currentMonthWorkdays
              .where((wd) => wd.worked)
              .fold<double>(0, (sum, wd) => sum + (wd.hours / 8.0));
          final String formattedWorkedDays = workedDaysCount % 1 == 0
              ? workedDaysCount.toInt().toString()
              : workedDaysCount.toStringAsFixed(1);

          // محاسبه مجموع دستمزد ماه جاری
          final int totalWageForMonth = currentMonthWorkdays.fold<int>(0, (sum, wd) => sum + (wd.wage ?? 0));
          final String formattedWage = totalWageForMonth.toPriceString();

          // فیلتر کردن پرداخت‌های ماه جاری
          final currentMonthPayments = paymentsController.payments.where((p) {
            final paymentJalali = JalaliUtils.parseJalali(p.value.jalaliDate); // p.value
            return paymentJalali.year == _focusedJalali.year && paymentJalali.month == _focusedJalali.month;
          }).toList();

          // محاسبه مجموع دریافتی ماه جاری
          final int totalPaymentsForMonth = currentMonthPayments.fold<int>(
            0,
            (sum, p) => sum + p.value.amount,
          );
          final String formattedPayments = totalPaymentsForMonth.toPriceString();
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
                    padding: const EdgeInsetsDirectional.symmetric(vertical: 10, horizontal: 40),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor.withAlpha(100)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NoteWorks(title: 'تعداد روزهای کارکرد', value: formattedWorkedDays, numberic: false),
                        NoteWorks(title: 'مجموع دستمزد ماه جاری', value: formattedWage, numberic: true),
                        NoteWorks(title: 'مجموع دریافتی ماه جاری', value: formattedPayments, numberic: true),
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
  const NoteWorks({super.key, required this.title, required this.value, this.numberic = false});

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
  const _DayCell({required this.jd, required this.worked, required this.isToday, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    // دریافت تم فعلی برنامه
    final theme = Theme.of(context);
    Color textColor = theme.textTheme.bodyMedium!.color!;
    Color bgColor;

    // تعیین رنگ پس زمینه بر اساس وضعیت کارکرد
    if (worked) {
      // اگر روز کار کرده باشد، از رنگ آبی ملایم استفاده کن
      bgColor = Colors.blue.shade100;
    } else {
      // در غیر این صورت، شفاف
      bgColor = Colors.transparent;
    }

    final bool isFriday = jd.weekDay == 7;
    if (isFriday) {
      textColor = Colors.red; // جمعه قرمز است
    }

    // استفاده از TweenAnimationBuilder برای انیمیشن ملایم هنگام نمایش سلول
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          // Transform.scale را برای انیمیشن مقیاس در صورت نیاز می توان فعال کرد
          child: Transform.scale(scale: 1.0, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(2), // فاصله بین سلول ها
        decoration: BoxDecoration(
          color: bgColor, // رنگ پس زمینه
          borderRadius: BorderRadius.circular(8), // گوشه های گرد
          border: Border.all(
            // رنگ و ضخامت border بر اساس روز جاری، روز کارکرد، یا روز عادی
            color: isToday
                ? Colors
                      .red // اگر روز جاری است، border قرمز
                : worked
                ? Colors
                      .blue // اگر روز کار شده، border آبی
                : Colors.grey.shade300, // در غیر این صورت، border خاکستری
            width: isToday ? 2 : 1, // ضخامت border
          ),
        ),
        alignment: Alignment.center, // مرکز کردن محتوا
        child: Text(
          '${jd.day}', // نمایش شماره روز
          style: TextStyle(
            fontWeight: FontWeight.bold,
            // رنگ متن بر اساس وضعیت کارکرد
            color: worked ? Colors.blue.shade900 : textColor,
            fontSize: worked ? 16 : 14, // اندازه فونت
          ),
        ),
      ),
    );
  }
}
