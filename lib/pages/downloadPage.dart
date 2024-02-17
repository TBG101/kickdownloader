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
      print(controller.videoDownloadPercentage.value);
      return controller.videoDownloadPercentage.value.toStringAsFixed(0);
    } else {
      return "Waiting for quee";
    }
  }

  deleteVOD(int i) {
    var element = controller.deleteFileDropdown(i);

    controller.animatedListKey.currentState!.removeItem(i,
        (context, animation) {
      return SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(
          opacity: animation,
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
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return AnimatedList(
        key: controller.animatedListKey,
        initialItemCount: controller.queeVideoDownload.length +
            controller.completedVideos.length,
        itemBuilder: (context, index, animation) {
          if (index < controller.queeVideoDownload.length) {
            return SizeTransition(
              sizeFactor: animation,
              child: FadeTransition(
                opacity: animation,
                child: VideoCard(
                  title:
                      "${controller.queeVideoDownload[index]["data"]["livestream"]["channel"]["user"]["username"]} - ${controller.queeVideoDownload[index]["data"]["livestream"]["session_title"]}",
                  image: controller.queeVideoDownload[index]["image"],
                  subtitle: textSelector(index),
                  download: index == 0 ? true : false,
                  cancelDownload: controller.cancelDownload,
                  deleteVOD: null,
                ),
              ),
            );
          }
          var i = index - (controller.queeVideoDownload.length);
          return SizeTransition(
            sizeFactor: animation,
            child: FadeTransition(
              opacity: animation,
              child: VideoCard(
                title:
                    "${controller.completedVideos[i]["streamer"]} - ${controller.completedVideos[i]["title"]}",
                image: controller.completedVideos[i]["image"],
                subtitle: "Downloaded",
                download: false,
                deleteVOD: () {
                  deleteVOD(i);
                },
              ),
            ),
          );
        },
      );
    });
  }
}
