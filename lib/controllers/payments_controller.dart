import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../models/payment.dart';

class PaymentsController extends GetxController {
  late final Box<PaymentModel> _paymentBox;

  final RxList<MapEntry<dynamic, PaymentModel>> payments =
      <MapEntry<dynamic, PaymentModel>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _paymentBox = Hive.box<PaymentModel>('payments');
    _refresh();
    _paymentBox.watch().listen((_) => _refresh());
  }

  void _refresh() {
    payments.assignAll(_paymentBox.toMap().entries);
  }

  Future<int> addPayment(PaymentModel payment) async {
    final key = await _paymentBox.add(payment);
    _refresh();
    return key;
  }

  Future<void> deletePayment(int key) async {
    await _paymentBox.delete(key);
    _refresh();
  }

  void editPayment(dynamic key, PaymentModel payment) async {
    await _paymentBox.put(key, payment);
    _refresh();
  }
}
