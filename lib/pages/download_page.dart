import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kickdownloader/utilities/logic.dart';
import 'package:kickdownloader/utilities/static_Functions.dart';
import 'package:kickdownloader/widgets/downloadPage/videoCard.dart';

class DownloadPage extends GetView<Logic> {
  const DownloadPage({super.key});

  String textSelector(int index) {
    if (controller.videoDownloadPercentage.value >= 99 &&
        controller.downloading.isTrue &&
        controller.queeVideoDownload[index]["downloading"] as bool) {
      return "Converting to mp4";
    } else if (controller.queeVideoDownload[index]["downloading"] as bool &&
        controller.videoDownloadPercentage.value < 100 &&
        controller.downloading.isTrue) {
      var (size, suffix) =
          StaticFunctions.formatBytes(controller.videoDownloadSizeBytes.value);
      var videoDownloadSizeMb =
          "${(size * controller.videoDownloadPercentage.value / 100).toStringAsFixed(2)} /${size.toStringAsFixed(2)} $suffix";

      return "${controller.videoDownloadPercentage.value.toStringAsFixed(0)}% - $videoDownloadSizeMb";
    } else {
      if (controller.queeVideoDownload[0]["downloading"] == true &&
          controller.downloading.isFalse) {
        return "Downloading is paused";
      }

      if (controller.downloading.isTrue) {
        return "Waiting for quee";
      } else {
        return "Downloading is paused";
      }
    }
  }

  void deleteVOD(int i, int animatedListIndex, int length) async {
    var element = controller.completedVideos[i];

    if (length != 1) {
      await controller.deleteFileDropdown(i);
    }

    controller.animatedListKey.currentState!.removeItem(
      animatedListIndex,
      duration: const Duration(milliseconds: 400),
      (context, animation) {
        return SizeTransition(
            axis: Axis.vertical,
            axisAlignment: -1,
            sizeFactor:
                CurvedAnimation(curve: Curves.easeIn, parent: animation),
            child: VideoCard(
              title: "${element["streamer"]} - ${element["title"]}",
              image: element["image"],
              subtitle: "Downloaded",
              download: false,
              deleteVOD: null,
            )
                .animate()
                .fadeOut(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeIn)
                .scaleY(
                    begin: 1,
                    end: 0,
                    alignment: Alignment.topCenter,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeIn));
      },
    );

    if (length == 1) {
      await Future.delayed(const Duration(milliseconds: 400))
          .then((value) => controller.deleteFileDropdown(i));
    }
  }

  void cancelDownload(int index) {
    var name =
        "${controller.queeVideoDownload[index]["username"]} - ${controller.queeVideoDownload[index]["title"]}";
    var img = controller.queeVideoDownload[index]["image"];
    var sub = textSelector(index);
    var download = index == 0 ? true : false;
    controller.queeVideoDownload.removeAt(0);
    if (index == 0) {
      controller.cancelDownload();
    }
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
    return Stack(
      children: [
        Obx(() {
          if (controller.queeVideoDownload.isEmpty &&
              controller.completedVideos.isEmpty) {
            return Center(
                child: const Text(
              "You have no videos",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: const Duration(milliseconds: 250)));
          }
          return AnimatedList(
            physics: const BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.fast,
                parent: BouncingScrollPhysics()),
            key: controller.animatedListKey,
            initialItemCount: controller.queeVideoDownload.length +
                controller.completedVideos.length +
                1,
            itemBuilder: (animatedListContext, index, animation) {
              if ((controller.queeVideoDownload.length +
                      controller.completedVideos.length) ==
                  index) {
                return const SizedBox(
                  height: 50,
                );
              }
              print("index is $index");
              if (index < controller.queeVideoDownload.length) {
                return Obx(() {
                  return VideoCard(
                      title:
                          "${controller.queeVideoDownload[index]["username"]} - ${controller.queeVideoDownload[index]["title"]}",
                      image: controller.queeVideoDownload[index]["image"],
                      subtitle: textSelector(index),
                      download: index == 0 ? true : false,
                      cancelDownload: () {
                        cancelDownload(index);
                      },
                      copyLink: () {
                        controller.copyLinkToClipboard(index, context,
                            compltedVideo: false);
                      });
                });
              }

              var i = (index - (controller.queeVideoDownload.length));
              print("i is $i");
              return Obx(
                () => SizeTransition(
                    key: UniqueKey(),
                    axis: Axis.vertical,
                    axisAlignment: -1,
                    sizeFactor:
                        CurvedAnimation(parent: animation, curve: Curves.ease),
                    child: FadeTransition(
                      opacity:
                          Tween<double>(begin: 0, end: 1).animate(animation),
                      child: VideoCard(
                        title:
                            "${controller.completedVideos[i]["streamer"]} - ${controller.completedVideos[i]["title"]}",
                        image: controller.completedVideos[i]["image"],
                        subtitle: controller.completedVideos[i]["status"] ==
                                "notFound"
                            ? "Video Not Found"
                            : "Downloaded",
                        download: false,
                        cancelDownload: null,
                        errorSubtitle: controller.completedVideos[i]
                                ["status"] ==
                            "notFound",
                        deleteVOD: () {
                          deleteVOD(
                              i,
                              index,
                              controller.queeVideoDownload.length +
                                  controller.completedVideos.length);
                        },
                        copyLink: () {
                          controller.copyLinkToClipboard(i, context);
                        },
                        vodData: () {
                          controller.showFileInfoDialog(i, context);
                        },
                        openPath: () {
                          controller.openDir(i);
                        },
                      ),
                    )),
              );
            },
          );
        }),
        if (controller.adState.loadedBannerAd)
          Align(
            alignment: Alignment.bottomCenter,
            child: AspectRatio(
              aspectRatio: 468 / 60,
              child: AdWidget(
                ad: controller.adState.myBanner!,
              ),
            ),
          ),
      ],
    );
  }
}
