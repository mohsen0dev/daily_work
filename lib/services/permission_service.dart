import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// سرویس مدیریت دسترسی‌های سیستم، به ویژه برای خواندن و نوشتن حافظه در اندروید.
class PermissionService extends GetxService {
  /// سطح API اندروید. در صورت غیر اندرویدی بودن، null است.
  int? _androidSdkInt;

  @override
  void onInit() {
    super.onInit();
    _checkApiLevel();
  }

  /// بررسی سطح API اندروید برای تصمیم‌گیری در مورد نوع دسترسی مورد نیاز.
  Future<void> _checkApiLevel() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      _androidSdkInt = androidInfo.version.sdkInt;
    }
  }

  /// بررسی می‌کند که آیا برنامه نیاز به درخواست دسترسی Legacy Storage دارد (API < 33).
  bool get _needsLegacyStoragePermission {
    // اگر اندروید نباشد یا سطح API >= 33 باشد، نیاز به دسترسی Legacy نداریم.
    // در API 33 به بعد، اگر از دایرکتوری‌های اپلیکیشن (مثل getApplicationDocumentsDirectory) استفاده کنیم،
    // نیازی به دسترسی عمومی ذخیره‌سازی نیست.
    return Platform.isAndroid && (_androidSdkInt != null && _androidSdkInt! < 33);
  }

  /// درخواست دسترسی‌های ذخیره‌سازی مورد نیاز بر اساس نسخه اندروید.
  /// برمی‌گرداند true در صورت موفقیت یا عدم نیاز به دسترسی.
  Future<bool> requestStoragePermissions() async {
    // اگر پلتفرم ویندوز، iOS یا API >= 33 باشد (و از دایرکتوری‌های داخلی استفاده کنیم)، نیازی به درخواست صریح نیست.
    if (!Platform.isAndroid || !_needsLegacyStoragePermission) {
      Get.log('Storage permissions not strictly required or API >= 33.');
      return true;
    }

    try {
      // برای نسخه‌های قدیمی (API < 33)، دسترسی ذخیره‌سازی را درخواست می‌کنیم.
      // این دسترسی معمولاً شامل WRITE_EXTERNAL_STORAGE است.
      final status = await Permission.storage.request();

      if (status.isGranted) {
        return true;
      } else if (status.isDenied || status.isPermanentlyDenied) {
        Get.log('دسترسی ذخیره‌سازی رد شد: $status');
        Get.snackbar(
          'دسترسی لازم',
          'لطفاً دسترسی به حافظه را برای انجام پشتیبان‌گیری و بازیابی مجاز کنید.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          mainButton: TextButton(
            onPressed: () {
              // هدایت کاربر به تنظیمات برنامه برای اعطای دسترسی دائم
              openAppSettings();
            },
            child: const Text('تنظیمات', style: TextStyle(color: Colors.yellowAccent)),
          ),
        );
        return false;
      }
      return status.isGranted;
    } catch (e) {
      Get.log('خطا در درخواست دسترسی ذخیره‌سازی: $e');
      return false;
    }
  }

  /// بررسی سریع وضعیت دسترسی بدون درخواست مجدد.
  /// برمی‌گرداند true اگر دسترسی اعطا شده باشد یا نیازی به آن نباشد.
  Future<bool> checkStoragePermissions() async {
    if (!Platform.isAndroid || !_needsLegacyStoragePermission) {
      return true;
    }
    final status = await Permission.storage.status;
    return status.isGranted;
  }
}
