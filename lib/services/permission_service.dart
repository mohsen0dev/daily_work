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
    // این متد دیگر در requestStoragePermissions استفاده نمی‌شود اما برای سازگاری حفظ می‌شود.
    return Platform.isAndroid && (_androidSdkInt != null && _androidSdkInt! < 33);
  }

  /// درخواست دسترسی‌های ذخیره‌سازی مورد نیاز بر اساس نسخه اندروید.
  /// برمی‌گرداند true در صورت موفقیت یا عدم نیاز به دسترسی.
  Future<bool> requestStoragePermissions() async {
    // اگر پلتفرم ویندوز، iOS یا وب باشد، نیازی به درخواست صریح نیست.
    if (!Platform.isAndroid) {
      Get.log('Storage permissions not strictly required.');
      return true;
    }

    // 1. تعیین مجوز مورد نیاز بر اساس سطح API
    final Permission permission;
    // Android 11 (API 30) به بالا نیاز به MANAGE_EXTERNAL_STORAGE دارد
    if (_androidSdkInt != null && _androidSdkInt! >= 30) {
      permission = Permission.manageExternalStorage;
      Get.log('Requesting MANAGE_EXTERNAL_STORAGE for API >= 30.');
    } else {
      // API < 30 از Permission.storage استفاده می‌کند.
      permission = Permission.storage;
      Get.log('Requesting Storage Permission for API < 30.');
    }

    try {
      // 2. درخواست مجوز
      final status = await permission.request();

      // 3. مدیریت وضعیت‌ها
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // اگر دسترسی به صورت دائمی رد شده باشد (یا برای MANAGE_EXTERNAL_STORAGE اعطا نشده باشد)
        Get.log('دسترسی ذخیره‌سازی رد شد (دائم): $status');
        Get.snackbar(
          'دسترسی لازم',
          'لطفاً دسترسی به تمام فایل‌ها را از تنظیمات برنامه مجاز کنید.',
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
      } else if (status.isDenied) {
        // اگر دسترسی موقتاً رد شده باشد
        Get.log('دسترسی ذخیره‌سازی رد شد (موقت): $status');
        Get.snackbar(
          'دسترسی لازم',
          'برای انجام عملیات، دسترسی به حافظه را مجاز کنید. لطفاً مجدداً تلاش کنید.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
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
    if (!Platform.isAndroid) {
      return true;
    }

    final Permission permission;
    if (_androidSdkInt != null && _androidSdkInt! >= 30) {
      permission = Permission.manageExternalStorage;
    } else {
      permission = Permission.storage;
    }

    final status = await permission.status;
    return status.isGranted;
  }
}
