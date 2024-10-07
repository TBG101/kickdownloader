import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:kickdownloader/my_colors.dart';
import 'package:kickdownloader/pages/download_page.dart';
import 'package:kickdownloader/utilities/logic.dart';
import 'package:kickdownloader/utilities/static_functions.dart';
import 'package:kickdownloader/widgets/drawer.dart';
import 'package:kickdownloader/widgets/homeWidgets/MyButton.dart';
import 'package:kickdownloader/widgets/homeWidgets/dropdownSelector.dart';
import 'package:kickdownloader/widgets/homeWidgets/inputStream.dart';
import 'package:kickdownloader/widgets/homeWidgets/streamThumbnail.dart';
import 'package:kickdownloader/widgets/homeWidgets/timeSelectorStart.dart';
import 'package:kickdownloader/widgets/homeWidgets/timeSelectorend.dart';
import 'package:kickdownloader/widgets/homeWidgets/streamFields.dart';

class Home extends GetView<Logic> {
  const Home({super.key});

  List<Widget> homeView(size, BuildContext context) {
    return [
      // STREAM THUMBNAIL.
      const StreamThumbnail(),
      // TEXT FOR STREAM FIELDS
      Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Obx(() => StreamFields(
              field: "Streamer", text: controller.streamer.value))),
      Obx(() => StreamFields(field: "Title", text: controller.title.value)),
      Obx(() =>
          StreamFields(field: "Stream date", text: controller.stramDate.value)),
      Obx(() => StreamFields(
          field: "Stream Length", text: controller.streamLength.value)),

      // INPUT FOR STREAM URL
      const InputStreamUrl(),

      // GET VOD DATA BUTTON
      Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 0),
          child: MyButton(
            text: 'Get VOD data',
            onTap: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              controller.fetchingData.value = true;

              try {
                await controller.getVodData();
              } catch (e) {
                if (controller.hasInternet == false) {
                  
                  StaticFunctions.showSnackBar(
                      title: "No internet", "check your internet");
                } else {
                  StaticFunctions.showSnackBar(
                      title: "Error Occured", "Unhandled Exception");
                  FirebaseCrashlytics.instance.log(e.toString());
                }
              }
              controller.fetchingData.value = false;
            },
            enabled: true,
          )),

      // QUALITY SELECTOR DROPDOWN
      const DropdownSelector(),

      // START ROW FOR THE TIME SELECTOR
      const TimeSelectorRowStart(),

      // END ROW FOR THE TIME SELECTOR
      const TimeSelectorRowEnd(),

      // DOWNLOAD BUTTON
      Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 10),
          child: Obx(
            () => MyButton(
              text: 'Download VOD',
              onTap: () {
                controller.downloadVodDataBtn();
              },
              enabled: controller.foundVideo.value &&
                  controller.lastVideoLink.isNotEmpty,
            ),
          )),
    ];
  }

  AppBar myAppBar() {
    return AppBar(
      title: const Text(
        "Kick VOD Downloader",
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: MyColors.gradient),
      ),
      backgroundColor: const Color(0x00000000),
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        if (controller.pageSelector.value == 0)
          IconButton(
            onPressed: () {
              controller.pageSelector.value = 1;
              controller.update();
            },
            icon: Obx(() {
              return Badge(
                  backgroundColor: Colors.redAccent,
                  alignment: Alignment.topRight,
                  offset: const Offset(5, -7),
                  isLabelVisible: controller.queeVideoDownload.isNotEmpty,
                  label: Text(controller.queeVideoDownload.length.toString(),
                      style: const TextStyle(color: Colors.white)),
                  child: const Icon(Icons.download_rounded));
            }),
          )
        else
          Obx(() {
            return IconButton(
                onPressed: () {
                  if (controller.queeVideoDownload.isNotEmpty &&
                      controller.downloading.value == false) {
                    controller.downloading.value = true;
                    controller.startQueeDownloadVOD();
                  } else {
                    // Implement pause button
                    controller.downloading.value = false;
                  }
                },
                icon: Icon(controller.downloading.value
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded));
          })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SafeArea(
      child: PopScope(
        canPop: false,
        onPopInvoked: (_) async {
          if (controller.pageSelector.value == 1) {
            controller.pageSelector.value = 0;
            controller.update();
          }
        },
        child: GetBuilder(
          init: controller,
          builder: (controller) => Scaffold(
            drawer: const MyDrawer(),
            appBar: myAppBar(),
            body: controller.pageSelector.value == 0
                ? ListView(
                    padding: const EdgeInsets.all(10),
                    children: homeView(size, context))
                : const DownloadPage(),
          ),
        ),
      ),
    );
  }
}
