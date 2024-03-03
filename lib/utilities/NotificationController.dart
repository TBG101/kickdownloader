import 'package:awesome_notifications/awesome_notifications.dart';
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

  static Future<void> onActionReceived(ReceivedAction action) async {
    final Logic controller = Get.find();
    if (controller.pageSelector.value != 1) controller.pageSelector.value = 1;
    print("pressed");
    controller.update();
  }
}
