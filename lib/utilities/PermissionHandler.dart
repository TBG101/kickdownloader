import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/myColors.dart';
import 'package:kickdownloader/utilities/MethodChannelHandler.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  // STORAGE
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

// STATUS
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

// INFO
  static Future<bool> showStorageInfo() async {
    var value = await Get.dialog(
      AlertDialog(
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
                Get.back(result: true);
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

  static Future<bool> showNotificationInfo() async {
    var x = await Get.dialog(AlertDialog(
      actionsAlignment: MainAxisAlignment.center,
      title: const Text("Notification Permission",
          style: TextStyle(fontFamily: "SpaceGrotesk")),
      content: const Text(
        "App needs notification permission to notify you about the download progress",
        style: TextStyle(fontFamily: "SpaceGrotesk"),
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
              Get.back(result: false);
            },
            child: const Text(
              "Don't Allow",
              style: TextStyle(
                  color: MyColors.white,
                  fontSize: 14,
                  fontFamily: "SpaceGrotesk"),
            )),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Get.back(result: true);
            },
            child: const Text(
              "Request",
              style: TextStyle(
                  color: MyColors.white,
                  fontSize: 14,
                  fontFamily: "SpaceGrotesk"),
            ))
      ],
    ));
    return x ?? false;
  }

  // RESUSED INFO
  static void showNotificationPermaRefused() {
    Get.dialog(
      AlertDialog(
        title: const Text("Notification Permission"),
        content:
            const Text("You can always enable the permission in app settings."),
        actions: [
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Get.back();
              },
              child: const Text(
                "Continue",
                style: TextStyle(
                    color: MyColors.white,
                    fontSize: 14,
                    fontFamily: "SpaceGrotesk"),
              )),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                openAppSettings();
                Get.back();
              },
              child: const Text(
                "App settings",
                style: TextStyle(
                    color: MyColors.white,
                    fontSize: 14,
                    fontFamily: "SpaceGrotesk"),
              )),
        ],
      ),
    );
  }

  static void storagePermissionRefused() {
    // IMPLEMENT FOR LOW THAN SPECIFIC API
    Get.dialog(const AlertDialog(
      title: Text("Disclaimer", style: TextStyle(fontFamily: "SpaceGrotesk")),
      content: Text("The app will not work without Storage Permission ",
          style: TextStyle(
              color: MyColors.white, fontSize: 16, fontFamily: "SpaceGrotesk")),
    ));
  }

  // STORAGE ONLY
  static void storagePathNotAvailable() {
    Get.dialog(
      const AlertDialog(
        title: Text("Path is not available",
            style: TextStyle(fontFamily: "SpaceGrotesk")),
        content: Text(
            "The save path selected is not a valid path. Please not the some device might restrict some folders, so to be safe create a new folder and use it as your save path"),
      ),
    );
  }

  // Check storage full implementation
  static Future<bool> storageFullImplementation() async {
    // STORAGE PERMISSION
    var status = await getStorageStatus();
    if (status == false) {
      var result = await showStorageInfo();
      if (!result) {
        storagePermissionRefused();
        return false;
      }
      await requestStoragePermission();
      if (await getStorageStatus() == false) {
        storagePermissionRefused();
        return false;
      }
    }
    return false;
  }

  // Check notifciation full implemenetaiton
  static Future<void> notificationFullImplementation() async {
    if (await getNotificationStatus() == false) {
      if (await showNotificationInfo()) {
        await requestNotificationPermission();
      } else {
        showNotificationPermaRefused();
      }
    }
  }
}
