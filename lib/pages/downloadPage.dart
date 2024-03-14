import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';
import 'package:kickdownloader/widgets/downloadPage/videoCard.dart';

class DownloadPage extends GetView<Logic> {
  const DownloadPage({super.key});

  String textSelector(int index) {
    if (controller.videoDownloadPercentage.value >= 99 &&
        controller.queeVideoDownload[index]["downloading"] as bool) {
      return "Converting to mp4";
    } else if (controller.queeVideoDownload[index]["downloading"] as bool &&
        controller.videoDownloadPercentage.value < 100) {
      var (size, suffix) =
          controller.formatBytes(controller.videoDownloadSizeBytes.value);
      var videoDownloadSizeMb =
          "${(size * controller.videoDownloadPercentage.value / 100).toStringAsFixed(2)} /${size.toStringAsFixed(2)} $suffix";

      return "${controller.videoDownloadPercentage.value.toStringAsFixed(0)}% - $videoDownloadSizeMb";
    } else {
      return "Waiting for quee";
    }
  }

  void deleteVOD(int i, int animatedListIndex) async {
    var element = controller.completedVideos[i];

    controller.animatedListKey.currentState!.removeItem(animatedListIndex,
        duration: const Duration(milliseconds: 250), (context, animation) {
      return SizeTransition(
        sizeFactor: CurvedAnimation(
            parent: animation, curve: const FlippedCurve(Curves.decelerate)),
        child: FadeTransition(
          opacity: CurvedAnimation(
              parent: animation, curve: const FlippedCurve(Curves.decelerate)),
          child: VideoCard(
            title: "${element["streamer"]} - ${element["title"]}",
            image: element["image"],
            subtitle: "Downloaded",
            download: false,
            deleteVOD: null,
          ),
        ),
      );
    });
    controller.deleteFileDropdown(i);
  }

  void cancelDownload(int index) {
    var name =
        "${controller.queeVideoDownload[index]["data"]["livestream"]["channel"]["user"]["username"]} - ${controller.queeVideoDownload[index]["data"]["livestream"]["session_title"]}";
    var img = controller.queeVideoDownload[index]["image"];
    var sub = textSelector(index);
    var download = index == 0 ? true : false;
    controller.cancelDownload();
    controller.animatedListKey.currentState!.removeItem(
      index,
      duration: const Duration(milliseconds: 250),
      (context, animation) {
        return SizeTransition(
          sizeFactor: CurvedAnimation(
              parent: animation, curve: const FlippedCurve(Curves.decelerate)),
          child: FadeTransition(
              opacity: CurvedAnimation(
                  parent: animation,
                  curve: const FlippedCurve(Curves.decelerate)),
              child: VideoCard(
                title: name,
                image: img,
                subtitle: sub,
                download: download,
              )),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.queeVideoDownload.isEmpty &&
          controller.completedVideos.isEmpty) {
        return const Center(
            child: Text(
          "You have no videos",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ));
      }
      return AnimatedList(
        key: controller.animatedListKey,
        initialItemCount: controller.queeVideoDownload.length +
            controller.completedVideos.length,
        itemBuilder: (animatedListContext, index, animation) {
          if (index < controller.queeVideoDownload.length) {
            return Obx(() {
              return VideoCard(
                title:
                    "${controller.queeVideoDownload[index]["data"]["livestream"]["channel"]["user"]["username"]} - ${controller.queeVideoDownload[index]["data"]["livestream"]["session_title"]}",
                image: controller.queeVideoDownload[index]["image"],
                subtitle: textSelector(index),
                download: index == 0 ? true : false,
                cancelDownload: () {
                  cancelDownload(index);
                },
                copyLink: null,
                vodData: null,
                deleteVOD: null,
                openPath: null,
              );
            });
          }

          var i = index - (controller.queeVideoDownload.length);
          return Obx(() {
            return VideoCard(
              title:
                  "${controller.completedVideos[i]["streamer"]} - ${controller.completedVideos[i]["title"]}",
              image: controller.completedVideos[i]["image"],
              subtitle: "Downloaded",
              download: false,
              deleteVOD: () {
                deleteVOD(i, index);
              },
              cancelDownload: null,
              copyLink: () {
                controller.copyLinkToClipboard(i, context);
              },
              vodData: () {
                controller.showFileInfoDialog(i, context);
              },
              openPath: () {
                controller.openDir(i);
              },
            );
          });
        },
      );
    });
  }
}
