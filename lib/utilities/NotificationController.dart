import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/PermissionHandler.dart';
import 'package:kickdownloader/utilities/logic.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationController {
  final _notification = AwesomeNotifications();

  Future<void> createDownloadNotifcation(
      int id, String title, String body) async {
    if (await PermissionHandler.getNotificationStatus() != true) {
      return; // early return if permission is not granted
    }
    AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: id,
      autoDismissible: false,
      channelKey: "channel",
      title: title,
      body: body,
      category: NotificationCategory.Progress,
      notificationLayout: NotificationLayout.ProgressBar,
      progress: 0,
      locked: true,
    ));
  }

  Future<void> updateNotificationEnd(
      int id, String title, String body, bool locked) async {
    if (await PermissionHandler.getNotificationStatus() != true) {
      return; // early return if permission is not granted
    }
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: "channel",
            title: title,
            body: body,
            category: NotificationCategory.Progress,
            notificationLayout: NotificationLayout.ProgressBar,
            progress: 100,
            locked: locked));
  }

  Future<void> updateNotification(int id, List file, String title, String body,
      double videoPercentage) async {
    if (await PermissionHandler.getNotificationStatus() != true) {
      return; // early return if permission is not granted
    }
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: "channel",
            title: title,
            body: body,
            category: NotificationCategory.Progress,
            notificationLayout: NotificationLayout.ProgressBar,
            progress: videoPercentage,
            locked: true,
            autoDismissible: false));
  }

  void dissmissNotification(int id) {
    AwesomeNotifications().dismiss(id);
  }

  static Future<void> onActionReceived(ReceivedAction action) async {
    final Logic controller = Get.find();
    if (controller.pageSelector.value != 1) controller.pageSelector.value = 1;
    print("pressed");
    controller.update();
  }

  void startListener() async {
    var status = await PermissionHandler.getNotificationStatus();
    if (status == true) {
      _notification.setListeners(
        onActionReceivedMethod: NotificationController.onActionReceived,
      );
    }
  }

  void showAlertDialog(BuildContext context) {
    Widget openSettings = TextButton(
      child: const Text("Open settings"),
      onPressed: () {
        openAppSettings();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Notification Denied"),
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
}
