import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart' as sh;

import '../controllers/workdays_controller.dart';
import '../controllers/payments_controller.dart';
import '../utils/jalali_utils.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final WorkDaysController workDaysController =
        Get.find<WorkDaysController>();
    final PaymentsController paymentsController =
        Get.find<PaymentsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('نمودارها'), centerTitle: true),
      body: Obx(() {
        final workdays = workDaysController.workdays.values.toList();
        final payments = paymentsController.payments
            .map((e) => e.value)
            .toList();

        final nowJ = sh.Jalali.now();
        final Map<int, int> earnedByMonth = {
          for (int m = 1; m <= 12; m++) m: 0,
        };
        final Map<int, int> paidByMonth = {for (int m = 1; m <= 12; m++) m: 0};

        for (final d in workdays) {
          final jd = JalaliUtils.parseJalali(d.jalaliDate);
          if (jd.year == nowJ.year) {
            earnedByMonth[jd.month] = earnedByMonth[jd.month]! + (d.wage ?? 0);
          }
        }
        for (final p in payments) {
          final jp = JalaliUtils.parseJalali(p.jalaliDate);
          if (jp.year == nowJ.year) {
            paidByMonth[jp.month] = paidByMonth[jp.month]! + p.amount;
          }
        }

        final barGroups = <BarChartGroupData>[];
        for (int m = 1; m <= 12; m++) {
          final earned = earnedByMonth[m]!;
          final paid = paidByMonth[m]!;
          if (earned > 0 || paid > 0) {
            barGroups.add(
              BarChartGroupData(
                x: m, // <- این باید با ماه واقعی داده‌ها مطابقت داشته باشد
                barRods: [
                  BarChartRodData(
                    toY: earned.toDouble(),
                    color: Colors.green,
                    width: 6,
                  ),
                  BarChartRodData(
                    toY: paid.toDouble(),
                    color: Colors.blue,
                    width: 6,
                  ),
                ],
              ),
            );
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'دستمزد (سبز) و دریافتی (آبی) بر حسب ماه - امسال',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                num result = value / 1000000;
                                final val = result % 2 == 0
                                    ? result.toInt()
                                    : result;
                                return SideTitleWidget(
                                  // axisSide: meta.axisSide,
                                  space: 12,
                                  angle: -0.5,
                                  meta: TitleMeta(
                                    min: meta.min,
                                    max: meta.max,
                                    parentAxisSize: meta.parentAxisSize,
                                    axisPosition: meta.axisPosition,
                                    appliedInterval: meta.appliedInterval,
                                    sideTitles: meta.sideTitles,
                                    formattedValue: '$val میلیون',
                                    axisSide: meta.axisSide,
                                    rotationQuarterTurns:
                                        meta.rotationQuarterTurns,
                                  ),
                                  child: Text(
                                    '$val میلیون',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final monthIndex = value.toInt();
                                String text;
                                switch (monthIndex) {
                                  case 1:
                                    text = 'فروردین';
                                    break;
                                  case 2:
                                    text = 'اردیبهشت';
                                    break;
                                  case 3:
                                    text = 'خرداد';
                                    break;
                                  case 4:
                                    text = 'تیر';
                                    break;
                                  case 5:
                                    text = 'مرداد';
                                    break;
                                  case 6:
                                    text = 'شهریور';
                                    break;
                                  case 7:
                                    text = 'مهر';
                                    break;
                                  case 8:
                                    text = 'آبان';
                                    break;
                                  case 9:
                                    text = 'آذر';
                                    break;
                                  case 10:
                                    text = 'دی';
                                    break;
                                  case 11:
                                    text = 'بهمن';
                                    break;
                                  case 12:
                                    text = 'اسفند';
                                    break;
                                  default:
                                    text = '';
                                    break;
                                }

                                return SideTitleWidget(
                                  // axisSide: meta.axisSide,
                                  meta: TitleMeta(
                                    min: meta.min,
                                    max: meta.max,
                                    parentAxisSize: meta.parentAxisSize,
                                    axisPosition: meta.axisPosition,
                                    appliedInterval: meta.appliedInterval,
                                    sideTitles: meta.sideTitles,
                                    formattedValue: text,
                                    axisSide: meta.axisSide,
                                    rotationQuarterTurns:
                                        meta.rotationQuarterTurns,
                                  ),
                                  space: 4,
                                  angle: -0.9, // زاویه به رادیان، حدود -30 درجه
                                  child: Text(
                                    text,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
