import 'package:flutter/material.dart';
import 'package:httpplugin/httpplugin.dart';
import 'package:live_anchor_project/common/http/error_deal.dart';
import 'package:live_anchor_project/common/http/http_channel.dart';
import 'package:live_anchor_project/common/langs/translation_service.dart';
import 'package:live_anchor_project/common/routers/pages.dart';
import 'package:live_anchor_project/common/store/store.dart';
import 'package:live_anchor_project/common/style/style.dart';
import 'package:live_anchor_project/common/utils/utils.dart';
import 'package:live_anchor_project/global.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'common/http/cache.dart';
import 'common/http/config.dart';
import 'common/http/containers.dart';

Future<void> main() async {
  await Global.init();
  await HttpChannel.channel.setUpChannel(
      config: HttpConfig(
          ip: "https://liveapi.starops.work",
          maxSlave: 8,
          maxLongRunningSlave: 5,
          statusCodeIgnoreRetry: [
            403
          ],
          errorDeal: CustomErrorDeal(),
          slaveCloseTime: 600,
          enableOauth: false,
          enableRedirect: false
      ),
      cache: AppCacheManager.cache
  );
  HttpChannel.channel.addTickContainers(AppRequest.request);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  static GlobalKey globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context,child) => RefreshConfiguration(
        headerBuilder: () =>  ClassicHeader(),
        footerBuilder: () =>  ClassicFooter(),
        hideFooterWhenNotFull: true,
        headerTriggerDistance: 80,
        maxOverScrollExtent: 100,
        footerTriggerDistance: 150,
        child: GetMaterialApp(
          title: 'News',
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,
          builder: EasyLoading.init(),
          translations: TranslationService(),
          navigatorObservers: [AppPages.observer],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: ConfigStore.to.languages,
          locale: ConfigStore.to.locale,
          fallbackLocale: Locale('en', 'US'),
          enableLog: true,
          logWriterCallback: Logger.write,
        ),
      ),
    );
  }
}
