import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:live_anchor_project/common/widget/widgets.dart';

import '../../common/http/http_channel.dart';
import '../../common/utils/utils.dart';

class SignLogic extends GetxController with Toast{
  var codeId;

  // email的控制器
  final TextEditingController phoneController = TextEditingController();
  // 密码的控制器
  final TextEditingController passController = TextEditingController();

  // 跳转 注册界面
  handleNavSignUp() {
    showToast( '跳转注册');
  }


  // 忘记密码
  handleFogotPassword() {
    showToast( '忘记密码');
  }

  void smsSend() {
    if (!duIsPhone(phoneController.value.text)) {
      showToast('请正确输入账号${phoneController.value.text}');
      return;
    }
    show();
    HttpChannel.channel.smsSend(
        phone: phoneController.value.text
    ).then((value) {
      dismiss();
      value.finalize(
          wrapper: WrapperModel(),
          failure: (e){
              showToast("$e");
              dismiss();
          },
          success: (data) {
            showToast("你的验证码为: ${data['code']}");
            codeId=data['codeId'];
            dismiss();
          }
      );
    });
  }

  // 执行登录操作
  handleSignIn() async {
    // Completer<bool> completer = Completer();
    if (!duIsPhone(phoneController.value.text)) {
      showToast('请正确输入账号');
      return;
    }
    HttpChannel.channel.logIn(phoneController.value.text
      , passController.value.text,
      codeId,
      type: "",)
        .then((value) => value.finalize(
        wrapper: WrapperModel(),
        failure: (e) {
          showToast(e);
          // completer.complete(false);
        },
        success: (data) {
          showToast('登陆成功 token:$data');
        }
    ));


    // Get.offAndToNamed(AppRoutes.Application);
    // if (!duCheckStringLength(_passController.value.text, 6)) {
    //   toastInfo(msg: '密码不能小于6位');
    //   return;
    // }

    // UserLoginRequestEntity params = UserLoginRequestEntity(
    //   email: emailController.value.text,
    //   password: duSHA256(passController.value.text),
    // );
    //
    // UserLoginResponseEntity userProfile = await UserAPI.login(
    //   params: params,
    // );
    // UserStore.to.saveProfile(userProfile);
    //
    // Get.offAndToNamed(AppRoutes.Application);
  }


  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
  }

  @override
  void onClose() {
    phoneController.dispose();
    passController.dispose();
    // TODO: implement onClose
    super.onClose();
  }
}
