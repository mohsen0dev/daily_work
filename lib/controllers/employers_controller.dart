import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../models/employer.dart';

class EmployersController extends GetxController {
  late final Box<EmployerModel> _employerBox;

  final RxList<MapEntry<dynamic, EmployerModel>> employers =
      <MapEntry<dynamic, EmployerModel>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _employerBox = Hive.box<EmployerModel>('employers');
    _refresh();
    _employerBox.watch().listen((_) => _refresh());
  }

  void _refresh() {
    employers.assignAll(_employerBox.toMap().entries);
  }

  Future<int> addEmployer({
    required String name,
    String? phone,
    String? note,
  }) async {
    final employer = EmployerModel(name: name, phone: phone, note: note);
    final key = await _employerBox.add(employer);
    _refresh();
    return key;
  }

  Future<void> updateEmployer({
    required int key,
    required EmployerModel updated,
  }) async {
    await _employerBox.put(key, updated);
    _refresh();
  }

  Future<void> deleteEmployer(int key) async {
    await _employerBox.delete(key);
    _refresh();
  }
}
