import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/employers_controller.dart';
import '../models/employer.dart';

class EmployersPage extends StatelessWidget {
  const EmployersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final EmployersController controller = Get.put(EmployersController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('کارفرماها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEmployerDialog(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.employers.isEmpty) {
          return const Center(child: Text('هیچ کارفرمایی ثبت نشده است'));
        }

        return ListView.builder(
          itemCount: controller.employers.length,
          itemBuilder: (context, index) {
            final entry = controller.employers[index];
            final employer = entry.value;
            final key = entry.key;

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 30),
                    child: child,
                  ),
                );
              },
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.blue.shade100,
                onTap: () {
                  // امکان نمایش جزئیات بیشتر یا دیالوگ
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(employer.name),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (employer.phone != null)
                            Text('تلفن: ${employer.phone}'),
                          if (employer.note != null)
                            Text('یادداشت: ${employer.note}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('بستن'),
                        ),
                      ],
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.business,
                      color: Colors.blue,
                      size: 28,
                    ),
                    title: Text(
                      employer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (employer.phone != null)
                          Text('تلفن: ${employer.phone}'),
                        if (employer.note != null)
                          Text('یادداشت: ${employer.note}'),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('ویرایش'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('حذف'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditEmployerDialog(
                            context,
                            controller,
                            key,
                            employer,
                          );
                        } else if (value == 'delete') {
                          _showDeleteConfirmDialog(
                            context,
                            controller,
                            key,
                            employer.name,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddEmployerDialog(
    BuildContext context,
    EmployersController controller,
  ) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('افزودن کارفرما'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'نام کارفرما *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'شماره تلفن',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'یادداشت',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                controller.addEmployer(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('افزودن'),
          ),
        ],
      ),
    );
  }

  void _showEditEmployerDialog(
    BuildContext context,
    EmployersController controller,
    dynamic key,
    Employer employer,
  ) {
    final nameController = TextEditingController(text: employer.name);
    final phoneController = TextEditingController(text: employer.phone ?? '');
    final noteController = TextEditingController(text: employer.note ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ویرایش کارفرما'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'نام کارفرما *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'شماره تلفن',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'یادداشت',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final updatedEmployer = Employer(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );
                controller.updateEmployer(key: key, updated: updatedEmployer);
                Navigator.pop(context);
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    EmployersController controller,
    dynamic key,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: Text('آیا مطمئن هستید که می‌خواهید "$name" را حذف کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteEmployer(key);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
