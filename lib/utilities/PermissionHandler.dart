import 'package:kickdownloader/utilities/MethodChannelHandler.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
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
}
