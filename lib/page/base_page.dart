import 'package:flutter/cupertino.dart';

import '../main.dart';

abstract class BasePage extends StatelessWidget {
  BasePage({Key? key}) : super(key: key);

  double getCurrentWidth(){
    return MyApp.globalKey.currentContext?.size?.width??0;
  }

  double getCurrentHeight(){
    return  MyApp.globalKey.currentContext?.size?.height??0;
  }
}