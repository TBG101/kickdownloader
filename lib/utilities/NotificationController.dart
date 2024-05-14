import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/PermissionHandler.dart';
import 'package:kickdownloader/utilities/logic.dart';

class NotificationController {
  final __notification = AwesomeNotifications();
  int lastUpdateTime = 0;
  final myNotifications = <int>{};
  Future<void> createDownloadNotifcation(
      int id, String title, String body) async {
    myNotifications.add(id);
    if (await PermissionHandler.getNotificationStatus() != true) {
      return; // early return if permission is not granted
    }
    __notification.createNotification(
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
    await __notification.createNotification(
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
    if (await PermissionHandler.getNotificationStatus() != true &&
        lastUpdateTime > (lastUpdateTime + 1000)) {
      return; // early return if permission is not granted
    }

    __notification.createNotification(
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
    lastUpdateTime = DateTime.timestamp().millisecondsSinceEpoch;
  }

  Future<void> failedDownloadNotification(
      int id, String title, String body) async {
    if (await PermissionHandler.getNotificationStatus() != true) {
      return; // early return if permission is not granted
    }
    __notification.createNotification(
        content: NotificationContent(
            id: id,
            channelKey: "channel",
            title: title,
            body: body,
            category: NotificationCategory.Status,
            notificationLayout: NotificationLayout.Default,
            locked: false));
  }

  void dissmissNotification(int id) {}

  void removeNotifications() {
    for (var id in myNotifications) {
      __notification.dismiss(id);
    }
  }

  Future<void> startListener() async {
    var status = await PermissionHandler.getNotificationStatus();
    if (status == true) {
      __notification.setListeners(
        onActionReceivedMethod: NotificationController.onActionReceived,
      );
    }
  }

  static Future<void> onActionReceived(ReceivedAction action) async {
    try {
      final Logic controller = Get.find<Logic>();
      if (controller.pageSelector.value != 1) controller.pageSelector.value = 1;
      controller.update();
    } catch (e) {}
  }
}
