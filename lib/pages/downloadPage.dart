import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';
import 'package:kickdownloader/widgets/downloadPage/videoCard.dart';

class DownloadPage extends GetView<Logic> {
  const DownloadPage({super.key});

  String textSelector(int index) {
    if ((controller.queeVideoDownload[index]["downloading"] as bool)) {
      return controller.videoDownloadPercentage.value.toStringAsFixed(0);
    } else if (controller.videoDownloadPercentage.value >= 100 &&
        (controller.queeVideoDownload[index]["downloading"] as bool)) {
      return "Converting to mp4";
    } else {
      return "name: waiting for quee";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListView.builder(
          itemCount: controller.queeVideoDownload.length +
              controller.completedVideos.length,
          itemBuilder: (context, index) {
            return Obx(
              () {
                if (index < controller.queeVideoDownload.length) {
                  return VideoCard(
                      title:
                          "${controller.queeVideoDownload[index]["data"]["livestream"]["channel"]["user"]["username"]} - ${controller.queeVideoDownload[index]["data"]["livestream"]["session_title"]}",
                      image: controller.queeVideoDownload[index]["image"],
                      subtitle: textSelector(index));
                }
                var i = index - (controller.queeVideoDownload.length);
                return VideoCard(
                    title:
                        "${controller.completedVideos[i]["streamer"]} - ${controller.completedVideos[i]["title"]}",
                    image: controller.completedVideos[i]["image"],
                    subtitle: "Downloaded");
              },
            );
          });
    });
  }
}
