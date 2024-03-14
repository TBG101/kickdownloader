import 'package:flutter/material.dart';
import 'package:kickdownloader/myColors.dart';
import 'package:kickdownloader/utilities/MethodChannelHandler.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  final MY_FONT = "zefa";

  static Future<void> requestStoragePermission() async {
    var ver = await MethodChannelHandler.getDeviceVersion();
    if (ver >= 30) {
      await Permission.manageExternalStorage.request();
    } else {
      await Permission.storage.request();
    }
  }

  static Future<void> requestNotificationPermission() async {
    await Permission.notification.request();
  }

  static Future<bool?> getNotificationStatus() async {
    var st = await Permission.notification.status;
    if (st.isGranted) {
      return true;
    } else if (st.isDenied) {
      return false;
    } else {
      return null;
    }
  }

  static Future<bool?> getStorageStatus() async {
    var ver = await MethodChannelHandler.getDeviceVersion();
    if (ver >= 30) {
      var st = await Permission.manageExternalStorage.status;
      if (st.isGranted) {
        return true;
      } else if (st.isDenied) {
        return false;
      } else {
        return false;
      }
    } else {
      var st = await Permission.storage.status;
      if (st.isGranted) {
        return true;
      } else if (st.isDenied) {
        return false;
      } else {
        return null;
      }
    }
  }

  static Future<bool> showStorageInfo(BuildContext context) async {
    var value = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Storage Permission",
            style: TextStyle(fontFamily: "SpaceGrotesk")),
        content: const Text(
          "The app needs Storage Permission to save the VOD to your desired folder, it is necessary to enable this permission or else the app will not work",
          style: TextStyle(fontSize: 16, fontFamily: "SpaceGrotesk"),
        ),
        actions: [
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                "Continue",
                style: TextStyle(
                    color: MyColors.white,
                    fontSize: 16,
                    fontFamily: "SpaceGrotesk"),
              ))
        ],
      ),
    );
    if (value == true) {
      return true;
    } else {
      return false;
    }
  }

  static void storagePermissionRefused(BuildContext context) {
    // IMPLEMENT FOR LOW THAN SPECIFIC API
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title:
              Text("Disclaimer", style: TextStyle(fontFamily: "SpaceGrotesk")),
          content: Text("The app will not work without Storage Permission ",
              style: TextStyle(
                  color: MyColors.white,
                  fontSize: 16,
                  fontFamily: "SpaceGrotesk")),
        );
      },
    );
  }

  static void storagePathNotAvailable(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text("Path is not available",
            style: TextStyle(fontFamily: "SpaceGrotesk")),
        content: Text(
            "The save path selected is not a valid path. Please not the some device might restrict some folders, so to be safe create a new folder and use it as your save path"),
      ),
    );
  }
}
