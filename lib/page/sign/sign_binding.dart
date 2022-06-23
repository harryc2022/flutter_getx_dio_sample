import 'package:get/get.dart';

import 'sign_logic.dart';

class SignBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SignLogic());
  }
}
