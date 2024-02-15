import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:kickdownloader/myColors.dart';
import 'package:kickdownloader/pages/Home.dart';
import 'package:kickdownloader/utilities/logic.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("video");
  await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            channelKey: 'channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: const Color(0xFF9D50DD),
            playSound: true,
            locked: true,
            ledColor: Colors.white)
      ],
      // Channel groups are only visual and are not required
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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: myColors.background,
        primaryColor: myColors.btnPrimary,
        fontFamily: "SpaceGrotesk",
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(myColors.btnPrimary),
            elevation: MaterialStateProperty.all(2),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final logic = Get.put(Logic(), permanent: true);
  @override
  Widget build(BuildContext context) {
    return const Home();
  }
}
