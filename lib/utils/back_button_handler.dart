import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class BackButtonHandler {
  static bool handleBackButton(BuildContext context, int currentIndex) {
    // If not on CalendarPage (index 0), navigate to CalendarPage
    if (currentIndex != 0) {
      // Find the MainNavigationPage and set current index to 0
      final navigator = Get.find<MainNavigationController>();
      navigator.setCurrentIndex(0);
      return true; // Consume the back button event
    }

    // If on CalendarPage, show exit confirmation dialog
    _showExitDialog(context);
    return true; // Consume the back button event
  }

  static void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'خروج از برنامه',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'آیا مطمئن هستید که می‌خواهید از برنامه خارج شوید؟',
            style: TextStyle(fontSize: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              child: const Text('لغو', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                SystemNavigator.pop(); // Exit the app
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('خروج', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }
}

// Controller to manage the current navigation index
class MainNavigationController extends GetxController {
  final RxInt _currentIndex = 0.obs;

  int get currentIndex => _currentIndex.value;

  void setCurrentIndex(int index) {
    _currentIndex.value = index;
  }
}
