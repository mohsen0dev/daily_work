import 'package:hive/hive.dart';

part 'payment.g.dart';

@HiveType(typeId: 3)
class PaymentModel extends HiveObject {
  // Store Jalali date as yyyy/MM/dd for Persian date persistence
  @HiveField(0)
  String jalaliDate;

  @HiveField(1)
  int? employerId; // optional filter by employer

  @HiveField(2)
  int amount; // in Tomans or Rials as you prefer

  @HiveField(3)
  String? note;

  PaymentModel({required this.jalaliDate, this.employerId, required this.amount, this.note});

  /// تبدیل مدل پرداخت به نقشه JSON برای پشتیبان‌گیری
  Map<String, dynamic> toJson() => {
    'jalaliDate': jalaliDate,
    'employerId': employerId,
    'amount': amount,
    'note': note,
  };
}
