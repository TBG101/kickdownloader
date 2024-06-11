import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:kickdownloader/firebase_options.dart';
import 'package:kickdownloader/my_colors.dart';
import 'package:kickdownloader/pages/home.dart';
import 'package:kickdownloader/utilities/logic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  final initFuture = MobileAds.instance.initialize();
  await Hive.initFlutter();
  await Hive.openBox("video");
  AwesomeNotifications().initialize(null, [
    NotificationChannel(
        channelKey: 'channel',
        channelName: 'Notification download notifier',
        channelDescription: 'Notification channel for download notifier',
        defaultColor: const Color.fromARGB(255, 9, 255, 0),
        playSound: true,
        locked: true,
        ledColor: Colors.white)
  ]);
  Get.put(Logic(initFuture), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kick VOD downloader',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        fontFamily: "SpaceGrotesk",
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MyColors.background,
        primaryColor: MyColors.green,
        focusColor: MyColors.green,
        textTheme:
            const TextTheme(titleLarge: TextStyle(fontFamily: "SpaceGrotesk")),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(MyColors.green),
            elevation: MaterialStateProperty.all(2),
          ),
        ),
      ),
      home: const Home(),
    );
  }
}
