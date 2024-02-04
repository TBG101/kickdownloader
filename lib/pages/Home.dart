import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/myColors.dart';
import 'package:kickdownloader/utilities/logic.dart';
import 'package:kickdownloader/widgets/drawer.dart';
import 'package:kickdownloader/widgets/homeWidgets/donwloadVodBtn.dart';
import 'package:kickdownloader/widgets/homeWidgets/dropdownSelector.dart';
import 'package:kickdownloader/widgets/homeWidgets/getVodDataBtn.dart';
import 'package:kickdownloader/widgets/homeWidgets/inputStream.dart';
import 'package:kickdownloader/widgets/homeWidgets/streamThumbnail.dart';
import 'package:kickdownloader/widgets/homeWidgets/timeSelectorStart.dart';
import 'package:kickdownloader/widgets/homeWidgets/timeSelectorend.dart';
import 'package:kickdownloader/widgets/streamFields.dart';

class Home extends GetView<Logic> {
  const Home({super.key});

  List<Widget> homeView(size) {
    return [
      // STREAM THUMBNAIL
      const StreamThumbnail(),

      // TEXT FOR STREAM FIELDS
      Obx(
        () => Padding(
          padding: const EdgeInsets.only(top: 5),
          child:
              StreamFields(field: "Streamer", text: controller.streamer.value),
        ),
      ),
      Obx(() => StreamFields(field: "Tile", text: controller.title.value)),
      Obx(() =>
          StreamFields(field: "Stream date", text: controller.stramDate.value)),
      Obx(() => StreamFields(
          field: "Stream Length", text: controller.streamLength.value)),

      // INPUT FOR STREAM URL
      const InputStreamUrl(),

      // GET VOD DATA BUTTON
      const VodDataBtn(),

      // QUALITY SELECTOR DROPDOWN
      const DropdownSelector(),

      // START ROW FOR THE TIME SELECTOR
      const TimeSelectorRowStart(),

      // END ROW FOR THE TIME SELECTOR
      const TimeSelectorRowEnd(),

      //  DOWNLOAD VOD BUTTON
      const DownloadVodBtn()
    ];
  }

  List<Widget> downloadsView() {
    return [
      Obx(() => Text("video ${controller.videoDownloadPercentage}")),
    ];
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SafeArea(
      child: WillPopScope(
          onWillPop: () async {
            if (controller.pageSelector.value == 1) {
              controller.pageSelector.value = 0;
              controller.update();
            }
            return false;
          },
          child: GetBuilder(
            init: controller,
            builder: (controller) => Scaffold(
              drawer: const myDrawer(),
              appBar: AppBar(
                actions: [
                  IconButton(
                      onPressed: () {
                        controller.pageSelector.value = 1;
                        controller.update();
                      },
                      icon: const Icon(Icons.download_rounded))
                ],
                title: const Text("Kick Downloader VOD"),
                backgroundColor: myColors.btnPrimary,
                elevation: 1,
                centerTitle: true,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ),
              body: ListView(
                  padding: const EdgeInsets.all(10),
                  children: (controller.pageSelector.value == 0)
                      ? homeView(size)
                      : downloadsView()),
            ),
          )),
    );
  }
}
