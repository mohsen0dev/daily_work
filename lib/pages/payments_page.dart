import 'package:daily_work/utils/price_format.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/page_controller/payments_page_controller.dart';
import '../controllers/employers_controller.dart';
import '../widgets/shared_filter_bar.dart';

/// صفحه نمایش لیست دریافتی‌ها و خلاصه‌ی آن‌ها.
/// امکان فیلتر کردن بر اساس کارفرما و بازه زمانی (ماهیانه) را فراهم می‌کند.
/// این صفحه یک StatelessWidget است و تمام منطق و حالت آن توسط [PaymentsPageController] مدیریت می‌شود.
class PaymentsPage extends StatelessWidget {
  /// سازنده PaymentsPage.
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // تزریق کنترلر صفحه پرداخت‌ها.
    final PaymentsPageController controller = Get.put(PaymentsPageController());

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => controller.showAddPaymentDialog(context),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            /// ویجت نوار فیلتر مشترک برای انتخاب کارفرما و ماه.
            Obx(
              () => SharedFilterBar(
                employersController: Get.find<EmployersController>(),
                initialSelectedEmployerId: controller.selectedEmployerId.value,
                initialSelectedMonths: controller.selectedMonths.toList(),
                onEmployerChanged: controller.onEmployerChanged,
                onDateFilterChanged: controller.onDateFilterChanged,
              ),
            ),
            Expanded(
              child: Obx(() {
                // بررسی اینکه آیا هیچ دریافتی ثبت نشده است
                if (controller.hasNoPayments) {
                  return const Center(child: Text('هیچ دریافتی ثبت نشده است'));
                }

                final RxList<PaymentSummary>? summariesToRender = controller.processedSummariess;
                final bool showNoEmployerPaymentsMessage = controller.showNoEmployerPaymentsMessage;

                return ListView.builder(
                  itemCount: summariesToRender!.length + (showNoEmployerPaymentsMessage ? 1 : 0),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      // آیتم اول همیشه کارت "کل دریافتی‌ها" است
                      return Column(
                        children: <Widget>[
                          _buildSummaryCard(
                            context,
                            summariesToRender[0],
                            false, // کارت کلی به صورت پیش‌فرض بسته باشد
                            index, // Index برای رنگ‌بندی
                            controller, // ارسال کنترلر به ویجت کمکی
                          ),
                          const Divider(),
                        ],
                      );
                    } else if (showNoEmployerPaymentsMessage && index == 1) {
                      // اگر پیام "تراکنشی یافت نشد" باید نمایش داده شود و این آیتم دوم است
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 150,
                          child: Center(
                            child: Text(
                              'تراکنشی برای این کارفرما در بازه انتخاب شده ثبت نشده است',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            ),
                          ),
                        ),
                      );
                    } else {
                      // باقی آیتم‌ها کارت‌های خلاصه‌ی کارفرماها هستند
                      // ایندکس را به خاطر جایگاه احتمالی پیام "تراکنشی یافت نشد" تنظیم می‌کنیم
                      final int actualSummaryIndex = index - (showNoEmployerPaymentsMessage ? 1 : 0);
                      return _buildSummaryCard(
                        context,
                        summariesToRender[actualSummaryIndex],
                        false, // کارت‌های کارفرما به صورت پیش‌فرض بسته باشند
                        index, // Index برای رنگ‌بندی
                        controller, // ارسال کنترلر به ویجت کمکی
                      );
                    }
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// متد کمکی برای ساخت کارت خلاصه (کارت کلی یا کارت کارفرما)
  Widget _buildSummaryCard(
    BuildContext context,
    PaymentSummary summary,
    bool initiallyExpanded,
    int cardIndex, //   cardIndex برای رنگ‌بندی
    PaymentsPageController controller,
  ) {
    // منطق رنگ‌بندی کارت بر اساس ایندکس در لیست رندر شده
    Color? cardColor;
    final brightness = Theme.of(context).brightness;

    if (brightness == Brightness.dark) {
      // رنگ‌بندی برای تم تاریک
      if (cardIndex == 0) {
        // کارت "کل دریافتی‌ها" در تم تاریک
        cardColor = Colors.teal.shade900;
      } else {
        // کارت‌های کارفرماها در تم تاریک (زوج/فرد)
        cardColor = cardIndex.isEven ? Colors.blueGrey.shade800 : Colors.grey.shade800;
      }
    } else {
      // رنگ‌بندی فعلی برای تم روشن
      if (cardIndex == 0) {
        cardColor = Colors.green[100];
      } else {
        cardColor = cardIndex.isEven ? Colors.amberAccent[100] : Colors.blue[100];
      }
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 30), child: child),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 4,
        color: cardColor,
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(summary.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${summary.total.toString().toPriceString()} تومان',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          children: summary.payments.map((entry) {
            final payment = entry.value;
            return Card(
              margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.payments, color: Colors.green),
                title: Text(
                  '${payment.amount.toString().toPriceString()} تومان',
                  style: const TextStyle(color: Colors.green),
                ),
                subtitle: Text(
                  'کارفرما: ${controller.getEmployerNameById(payment.employerId)}\n${payment.jalaliDate}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => controller.showEditPaymentDialog(context, entry.key, payment),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => controller.showDeleteConfirmDialog(context, entry.key, payment.amount),
                    ),
                  ],
                ),
                onTap: () => controller.showPaymentDetails(context, payment),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
