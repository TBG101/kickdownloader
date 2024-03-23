import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:kickdownloader/myColors.dart';
import 'package:kickdownloader/pages/Home.dart';
import 'package:kickdownloader/utilities/logic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(Logic(), permanent: true);
  await Hive.initFlutter();
  await Hive.openBox("video");
  await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            channelKey: 'channel',
            channelName: 'Notification download notifier',
            channelDescription: 'Notification channel for download notifier',
            defaultColor: const Color(0xFF9D50DD),
            playSound: true,
            locked: true,
            ledColor: Colors.white)
      ],
      debug: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kick VOD donwloader',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        fontFamily: "SpaceGrotesk",
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MyColors.background,
        primaryColor: MyColors.green,
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
