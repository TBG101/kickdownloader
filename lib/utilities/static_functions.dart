import 'dart:io';
import 'dart:math';

class StaticFunctions {
  static (double, String) formatBytes(int bytes) {
    if (bytes <= 0) return (0, "B");
    const suffixes = ["B", "KB", "MB", "GB"];
    final i = (log(bytes) / log(1024)).floor();
    return (((bytes / pow(1024, i))), suffixes[i]);
  }

  static bool validURL(String url) {
    RegExp validLinkPattern =
        RegExp(r'^(kick.com|https://kick.com)/video/[a-zA-Z0-9-]+$');
    return validLinkPattern.hasMatch(url);
  }

  static String thumbnailLink(String source) {
    final x = (source).split("\/");
    return "https://images.kick.com/video_thumbnails/${x[6]}/${x[12]}/480.webp";
  }

  static Future<void> deleteDir(String path) async {
    try {
      await Directory(path).delete(recursive: true);
    } catch (_) {}
  }

  static int convertToMillisecond(int h, int m, int s) {
    return (h * 60 * 60 + m * 60 + s) * 1000;
  }

  static Future waitTimer() async {
    return await Future.delayed(const Duration(seconds: 1));
  }

  static String getDir(String path) {
    final x = path.split("/");
    x.removeLast();
    return "${x.join("/")}/";
  }
}
