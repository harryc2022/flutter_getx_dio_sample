
import 'package:flutter_easyloading/flutter_easyloading.dart';

mixin Toast {

  /// 显示加载框
  Future<void> show([String status = "loading..."]){ ///请求中
    return EasyLoading.show(status: status, maskType: EasyLoadingMaskType.clear);
  }

  /// 显示toast
  Future<void> showToast(String status, {Duration? duration,
    EasyLoadingToastPosition? toastPosition, EasyLoadingMaskType? maskType,
    bool? dismissOnTap}) {
    return EasyLoading.showToast(status, duration: duration,
        toastPosition: toastPosition, maskType: maskType,
        dismissOnTap: dismissOnTap);
  }

  /// 显示完成
  Future<void> dismiss(){
    return EasyLoading.dismiss();
  }

  /// 显示消息
  Future<void> showInfo(String status){
    return EasyLoading.showInfo(status);
  }
}

