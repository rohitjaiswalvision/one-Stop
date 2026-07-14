import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ModuleHelper {

  static ModuleModel? getModule() {
    return Get.find<SplashController>().module;
  }

  static ModuleModel? getCacheModule() {
    return Get.find<SplashController>().getCacheModule();
  }

  static Module getModuleConfig(String? moduleType) {
    return Get.find<SplashController>().getModuleConfig(moduleType);
  }

  /// Whether we are dealing with the service module. Prefers the type carried on the
  /// data itself (an item/store may outlive a module switch) and falls back to the
  /// module currently selected.
  static bool isService({String? moduleType}) {
    if (moduleType != null && moduleType.isNotEmpty) {
      return moduleType == AppConstants.service;
    }
    final ModuleModel? module = getModule() ?? getCacheModule();
    return module?.moduleType == AppConstants.service;
  }

}