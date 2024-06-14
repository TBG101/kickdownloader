import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/my_colors.dart';

class StaticFunctions {
  static void showSnackBar(String message, {String? title}) {
    Get.rawSnackbar(
        title: title,
        message: message,
        barBlur: 0,
        onTap: (snack) {
          Get.closeCurrentSnackbar();
        },
        isDismissible: true,
        borderRadius: 10,
        overlayBlur: 0.5,
        icon: const Icon(Icons.error),
        margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 50),
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        boxShadows: [
          const BoxShadow(
              color: Color.fromARGB(121, 255, 55, 55),
              blurRadius: 10,
              spreadRadius: 2)
        ],
        backgroundGradient: MyColors.gradientOnError,
        padding: const EdgeInsets.only(left: 20, top: 15, bottom: 15));
  }

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
