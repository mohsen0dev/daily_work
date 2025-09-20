import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../controllers/workdays_controller.dart';
import 'day_form_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // Use the existing singleton instance registered in main.dart
  final WorkDaysController workDaysController = Get.find<WorkDaysController>();

  Jalali _focusedJalali = Jalali.now();
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
                _selectedDay.value = 1;
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
                _selectedDay.value = 1;
              });
              // Calling update() to refresh the data in controller.
              workDaysController.update();
            },
          ),
        ],
      ),
      // Use Obx to rebuild the widget when any Rx variable changes.
      body: Obx(() {
        final monthLength = _focusedJalali.monthLength;
        final firstWeekDay = Jalali(
          _focusedJalali.year,
          _focusedJalali.month,
          1,
        ).weekDay;
        final today = Jalali.now();
        List<Widget> dayWidgets = [];

        for (int i = 1; i < firstWeekDay; i++) {
          dayWidgets.add(const SizedBox());
        }

        for (int day = 1; day <= monthLength; day++) {
          final jd = Jalali(_focusedJalali.year, _focusedJalali.month, day);
          final wd = workDaysController.getByJalali(jd);
          final worked = wd?.worked == true;
          final isToday =
              (jd.year == today.year &&
              jd.month == today.month &&
              jd.day == today.day);
          final isSelected = day == _selectedDay.value;

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

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Text('ش'),
                    Text('ی'),
                    Text('د'),
                    Text('س'),
                    Text('چ'),
                    Text('پ'),
                    Text('ج'),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 7,
                    children: dayWidgets,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  final Jalali jd;
  final bool worked;
  final bool isToday;
  final bool isSelected;

  const _DayCell({
    required this.jd,
    required this.worked,
    required this.isToday,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (worked) {
      bg = Colors.blue.shade100;
    } else {
      bg = Colors.transparent;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      builder: (context, value, child) {
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
                : Colors.grey.shade300,
            width: isToday ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '${jd.day}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: worked ? Colors.blue.shade900 : Colors.black,
            fontSize: worked ? 16 : 14,
          ),
        ),
      ),
    );
  }
}
