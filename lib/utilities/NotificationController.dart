import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';
import 'package:permission_handler/permission_handler.dart';

enum MyPermissionStatus { granted, limited, denied, deniedForever, unknown }

class NotificationController {
  MyPermissionStatus _status = MyPermissionStatus.unknown;
  NotificationController() {
    _status = MyPermissionStatus.unknown;
  }

  Future<void> requestNotification() async {
    var s = await Permission.notification.request();
    if (s.isPermanentlyDenied || s.isDenied) {
      _status = MyPermissionStatus.denied;
      if (s.isDenied) {
        requestNotification();
      } else {
        _status = MyPermissionStatus.deniedForever;
      }
    } else if (s.isLimited)
      _status = MyPermissionStatus.limited;
    else {
      _status = MyPermissionStatus.granted;
    }
  }

  MyPermissionStatus get status => _status;

  void showAlertDialog(BuildContext context) {
    Widget openSettings = TextButton(
      child: const Text("Open settings"),
      onPressed: () {},
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Notification Denied"),
      content: const Text(
          "The app uses notification to show you the progress of the download.\nIf you want to enable notification open app settings"),
      actions: [
        openSettings,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static Future<void> onActionReceived(ReceivedAction action) async {
    final Logic controller = Get.find();
    if (controller.pageSelector.value != 1) controller.pageSelector.value = 1;
    print("pressed");
    controller.update();
  }
}
