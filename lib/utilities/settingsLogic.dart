import 'package:file_picker/file_picker.dart';
import 'package:kickdownloader/utilities/hive_logic.dart';
import 'package:kickdownloader/utilities/PermissionHandler.dart';

class SettingsController {
  String? savedDir;

  bool storagePermission = false;
  bool askDownloadAlways = false;

  bool notificationPermission = false;
  bool notificationComplete = true;
  bool notificationFailure = true;
  bool notificationEnable = false;

  void saveToHive() {
    HiveLogic.setStoreAskDownloadAlways(askDownloadAlways);
    HiveLogic.setStoreNotificationComplete(notificationComplete);
    HiveLogic.setStoreNotificationFailure(notificationEnable);
    HiveLogic.setStoreNotificationFailure(notificationFailure);
  }

  Future<void> initSettings() async {
    savedDir = HiveLogic.getSavePath;
    askDownloadAlways = HiveLogic.getStoreAskDownloadAlways;
    notificationEnable = HiveLogic.getStoreNotificationEnable;
    notificationComplete = HiveLogic.getStoreNotificationComplete;
    notificationFailure = HiveLogic.getStoreNotificationFailure;
    storagePermission = await PermissionHandler.getStorageStatus() ?? false;
    notificationPermission =
        await PermissionHandler.getNotificationStatus() ?? false;
  }

  // Switch Values
  void switchNotificationEnable() {
    notificationEnable = !notificationEnable;
  }

  void switchNotificationFailure() {
    notificationFailure = !notificationFailure;
  }

  void switchNotificationComplete() {
    notificationComplete = !notificationComplete;
  }

// __askDownloadAlways METHODS
  void switchAskDownloadAlways() {
    askDownloadAlways = !askDownloadAlways;
  }

// change the save directory
  Future<bool> savePathSelector({bool selectNew = false}) async {
    if (savedDir != null && !askDownloadAlways && !selectNew) {
      return true; // early Return if we already have a working path
    }

    var savePath = await FilePicker.platform.getDirectoryPath();

    if (savePath != "/" && savePath != null) {
      savedDir = savePath;
      HiveLogic.setStoreSavePath(savePath);
      return true;
    } else {
      PermissionHandler.storagePathNotAvailable();
      return false;
    }
  }
}
