import 'package:file_picker/file_picker.dart';
import 'package:kickdownloader/utilities/HiveLogic.dart';
import 'package:kickdownloader/utilities/PermissionHandler.dart';

class SettingsController {
  String? _savedDir;

  void setSavedDir(String? path) {
    _savedDir = path;
  }

  String? get getSavedDir => _savedDir;

  Future<bool> savePathSelector() async {
    if (_savedDir != null) {
      return true; // early Return if we already have a working path
    }

    var savePath = await FilePicker.platform.getDirectoryPath();

    if (savePath != "/" && savePath != null) {
      _savedDir = savePath;
      HiveLogic.setStoreSavePath(savePath);
      return true;
    } else {
      PermissionHandler.storagePathNotAvailable();
      return false;
    }
  }
}
