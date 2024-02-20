import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';

class NotificationController {
  static Future<void> onActionReceived(ReceivedAction action) async {
    final Logic controller = Get.find();
    if (controller.pageSelector.value != 1) controller.pageSelector.value = 1;
    print("pressed");
    controller.update();
  }
}
