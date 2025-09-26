import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart' as sh;
// import 'package:shamsi_date/shamsi_date.dart' as sh;
import '../controllers/employers_controller.dart';

/// یک ویجت نوار فیلتر قابل استفاده مجدد که امکان فیلتر کردن بر اساس کارفرما
/// و انتخاب چندین ماه را فراهم می‌کند. این ویجت State داخلی خود را با
/// مقادیر اولیه از والد همگام می‌کند و تغییرات را از طریق callbackها به والد اطلاع می‌دهد.
class SharedFilterBar extends StatefulWidget {
  /// کنترلر کارفرماها برای دسترسی به لیست کارفرماها.
  final EmployersController employersController;

  /// شناسه کارفرمای انتخاب شده اولیه. اگر null باشد، به معنی "همه کارفرماها" است.
  final int? initialSelectedEmployerId;

  /// لیستی از ماه‌های انتخاب شده اولیه.
  final List<sh.Jalali> initialSelectedMonths;

  /// تابعی که هنگام تغییر کارفرمای انتخاب شده فراخوانی می‌شود.
  final ValueChanged<int?> onEmployerChanged;

  /// تابعی که هنگام تغییر لیست ماه‌های انتخاب شده فراخوانی می‌شود.
  final ValueChanged<List<sh.Jalali>> onDateFilterChanged;

  /// سازنده SharedFilterBar.
  const SharedFilterBar({
    super.key,
    required this.employersController,
    required this.initialSelectedEmployerId,
    required this.initialSelectedMonths,
    required this.onEmployerChanged,
    required this.onDateFilterChanged,
  });

  @override
  State<SharedFilterBar> createState() => _SharedFilterBarState();
}

/// State مربوط به ویجت SharedFilterBar.
class _SharedFilterBarState extends State<SharedFilterBar> {
  late int? _selectedEmployerId;
  late List<sh.Jalali> _selectedMonths;

  /// مقداردهی اولیه State با استفاده از مقادیر اولیه فراهم شده توسط ویجت والد.
  @override
  void initState() {
    super.initState();
    _selectedEmployerId = widget.initialSelectedEmployerId;
    _selectedMonths = List.from(
      widget.initialSelectedMonths,
    ); // ایجاد کپی برای جلوگیری از تغییر مستقیم لیست والد
  }

  /// این متد برای همگام‌سازی state داخلی ویجت با state صفحه والد است.
  /// هرگاه مقادیر initialSelectedEmployerId یا initialSelectedMonths در ویجت والد تغییر کند،
  /// state داخلی این ویجت نیز به‌روزرسانی می‌شود.
  @override
  void didUpdateWidget(covariant SharedFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedEmployerId != _selectedEmployerId) {
      setState(() {
        _selectedEmployerId = widget.initialSelectedEmployerId;
      });
    }
    // بررسی تفاوت لیست‌ها با مقایسه محتوا (نه فقط رفرنس)
    if (!_listEquals(widget.initialSelectedMonths, _selectedMonths)) {
      setState(() {
        _selectedMonths = List.from(widget.initialSelectedMonths);
      });
    }
  }

  /// متد کمکی برای مقایسه محتوای دو لیست Jalali.
  bool _listEquals(List<sh.Jalali> list1, List<sh.Jalali> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].year != list2[i].year || list1[i].month != list2[i].month) {
        return false;
      }
    }
    return true;
  }

  /// ساختار اصلی UI نوار فیلتر.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 12, 8, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.fromBorderSide(BorderSide(color: context.theme.dividerColor.withAlpha(60))),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: IntrinsicHeight(
        // برای هم‌قد کردن ویجت‌های داخل Row
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int?>(
                borderRadius: BorderRadius.circular(10),
                value: _selectedEmployerId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'فیلتر کارفرما',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('همه کارفرماها')),
                  ...widget.employersController.employers.map((entry) {
                    return DropdownMenuItem<int?>(value: entry.key, child: Text(entry.value.name));
                  }),
                ],
                onChanged: (v) {
                  // state داخلی را آپدیت کرده و به والد اطلاع می‌دهیم
                  setState(() => _selectedEmployerId = v);
                  widget.onEmployerChanged(v);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(_getMonthButtonText(), overflow: TextOverflow.ellipsis),
                onPressed: () async {
                  final pickedList = await _showMultiMonthPicker(
                    context,
                    initialDate: _selectedMonths.isNotEmpty ? _selectedMonths.first : sh.Jalali.now(),
                    initiallySelectedMonths: _selectedMonths,
                  );

                  if (pickedList != null) {
                    pickedList.sort((a, b) => a.compareTo(b));
                    // state داخلی را آپدیت کرده و به والد اطلاع می‌دهیم
                    setState(() => _selectedMonths = pickedList);
                    widget.onDateFilterChanged(pickedList);
                  }
                },
              ),
            ),

            //!   دکمه حذف فیلتر تاریخ
            // if (_selectedMonths.isNotEmpty)
            //   Center( // Center کردن IconButton تا کش نیاید
            //     child: IconButton(
            //       tooltip: 'حذف فیلتر ماه',
            //       onPressed: () {
            //         setState(() => _selectedMonths = []);
            //         widget.onDateFilterChanged([]);
            //       },
            //       icon: const Icon(Icons.clear),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  /// متنی که روی دکمه انتخاب ماه نمایش داده می‌شود.
  /// اگر هیچ ماهی انتخاب نشده باشد، "انتخاب ماه" را نشان می‌دهد.
  /// اگر یک ماه انتخاب شده باشد، نام و سال آن ماه را نشان می‌دهد.
  /// اگر چندین ماه انتخاب شده باشد، تعداد ماه‌های انتخاب شده را نشان می‌دهد.
  String _getMonthButtonText() {
    if (_selectedMonths.isEmpty) {
      return 'انتخاب ماه';
    } else if (_selectedMonths.length == 1) {
      return '${_selectedMonths.first.formatter.mN} ${_selectedMonths.first.year}';
    } else {
      return '${_selectedMonths.length} ماه انتخاب شده';
    }
  }
}

// ------------------- کد دیالوگ انتخابگر ماه -------------------
// این کدها به این فایل منتقل شدند تا همه چیز مرتبط با فیلتر یکجا باشد

/// تابع کمکی برای نمایش دیالوگ انتخاب چندگانه ماه شمسی.
/// [initialDate] تاریخ اولیه برای نمایش سال در تقویم.
/// [initiallySelectedMonths] لیست ماه‌هایی که در ابتدا باید انتخاب شده باشند.
Future<List<sh.Jalali>?> _showMultiMonthPicker(
  BuildContext context, {
  required sh.Jalali initialDate,
  required List<sh.Jalali> initiallySelectedMonths,
}) async {
  return await showDialog<List<sh.Jalali>>(
    context: context,
    builder: (BuildContext context) {
      return _MonthPickerDialog(initialDate: initialDate, initiallySelectedMonths: initiallySelectedMonths);
    },
  );
}

/// ویجت دیالوگ انتخاب چندگانه ماه شمسی.
class _MonthPickerDialog extends StatefulWidget {
  /// تاریخ اولیه برای نمایش سال در تقویم.
  final sh.Jalali initialDate;

  /// لیستی از ماه‌هایی که در ابتدا باید انتخاب شده باشند.
  final List<sh.Jalali> initiallySelectedMonths;

  /// سازنده _MonthPickerDialog.
  const _MonthPickerDialog({required this.initialDate, required this.initiallySelectedMonths});

  @override
  _MonthPickerDialogState createState() => _MonthPickerDialogState();
}

/// State مربوط به دیالوگ _MonthPickerDialog.
class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _selectedYear;
  late List<sh.Jalali> _selectedMonths;

  /// لیست ثابت نام ماه‌های شمسی.
  static const List<String> _monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  /// مقداردهی اولیه State دیالوگ با سال و ماه‌های انتخاب شده اولیه.
  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    // ایجاد یک کپی از لیست برای مدیریت انتخاب‌ها در دیالوگ
    _selectedMonths = List.from(widget.initiallySelectedMonths);
  }

  /// ساختار اصلی UI دیالوگ انتخاب ماه.
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selectedYear--)),
          Text(_selectedYear.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              // اجازه ندهید به سال‌های آینده برود
              if (_selectedYear < sh.Jalali.now().year) {
                setState(() => _selectedYear++);
              }
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        height: 300,
        child: GridView.builder(
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.8,
          ),
          itemBuilder: (context, index) {
            final month = index + 1;
            final monthDate = sh.Jalali(_selectedYear, month, 1);

            // تعیین اینکه آیا یک ماه قابل انتخاب است (نمی‌توان ماه‌های آینده را انتخاب کرد)
            final bool isEnabled =
                _selectedYear < sh.Jalali.now().year ||
                (_selectedYear == sh.Jalali.now().year && month <= sh.Jalali.now().month);

            // بررسی اینکه آیا این ماه در حال حاضر انتخاب شده است
            final bool isSelected = _selectedMonths.any(
              (d) => d.year == monthDate.year && d.month == monthDate.month,
            );

            return InkWell(
              onTap: isEnabled
                  ? () {
                      setState(() {
                        if (isSelected) {
                          _selectedMonths.removeWhere(
                            (d) => d.year == monthDate.year && d.month == monthDate.month,
                          );
                        } else {
                          _selectedMonths.add(monthDate);
                        }
                      });
                    }
                  : null, // اگر فعال نباشد، onTap نیز null است
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor.withAlpha(570) : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _monthNames[index],
                    style: TextStyle(
                      color: isEnabled ? null : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // بازگشت null در صورت لغو
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedMonths), // بازگشت لیست ماه‌های انتخاب شده
          child: const Text('تایید'),
        ),
      ],
    );
  }
}
