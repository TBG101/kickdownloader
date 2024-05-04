import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/myColors.dart';
import 'package:kickdownloader/utilities/PermissionHandler.dart';
import 'package:kickdownloader/utilities/logic.dart';

class Settings extends GetView<Logic> {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Settings",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: MyColors.gradient),
          ),
          backgroundColor: const Color(0x00000000),
          centerTitle: true,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Get.back(),
            ),
          ),
        ),
        body: Obx(() {
          return ListView(
            children: [
              const ListTile(
                title: Text("Language"),
                subtitle: Text("English (more coming soon)"),
              ),
              const Divider(),
              ListTile(
                title: const Text("Save path"),
                subtitle: Text(controller.settingsController.value.savedDir ??
                    "No save path"),
                onTap: () async {
                  await controller.settingsController.value
                      .savePathSelector(selectNew: true);
                  controller.settingsController.refresh();
                  controller.settingsController.value.saveToHive();
                },
              ),
              ListTile(
                  title: const Text("Ask Download Folder"),
                  subtitle: const Text(
                      "Ask where to download everytime you download a new VOD"),
                  trailing: Switch(
                    activeColor: MyColors.greenDownloadPage,
                    value:
                        controller.settingsController.value.askDownloadAlways,
                    onChanged: (_) async {
                      controller.settingsController.value.askDownloadAlways =
                          !controller
                              .settingsController.value.askDownloadAlways;
                      controller.settingsController.refresh();
                      controller.settingsController.value.saveToHive();
                    },
                  )),
              // store ask permission, if not storagePermission
              if (!controller.settingsController.value.storagePermission)
                ListTile(
                  title: const Text("Ask storage permission"),
                  onTap: () async {
                    await PermissionHandler.storageFullImplementation();
                    await controller.settingsController.value.initSettings();
                    controller.settingsController.refresh();
                    controller.settingsController.value.saveToHive();
                  },
                ),
              const Divider(),
              // NOTIFICATION ENABLE
              ListTile(
                title: const Text("Notifications"),
                subtitle: const Text("Enable or disable notifications"),
                trailing: Switch(
                  activeColor: MyColors.greenDownloadPage,
                  value: controller.settingsController.value.notificationEnable,
                  onChanged: (_) {
                    
                    controller.settingsController.value
                        .switchNotificationEnable();
                    controller.settingsController.refresh();
                    controller.settingsController.value.saveToHive();
                  },
                ),
              ),
              // NOTIFICATION COMPLETE
              ListTile(
                  title: const Text("Notifications notify on complete"),
                  trailing: Switch(
                    activeColor: MyColors.greenDownloadPage,
                    value: controller
                        .settingsController.value.notificationComplete,
                    onChanged: (_) {
                      controller.settingsController.value
                          .switchNotificationComplete();
                      controller.settingsController.refresh();
                      controller.settingsController.value.saveToHive();
                    },
                  )),
              // NOTIFICATION FAILURE
              ListTile(
                  title: const Text("Notifications notify on failure"),
                  trailing: Switch(
                    activeColor: MyColors.greenDownloadPage,
                    value:
                        controller.settingsController.value.notificationFailure,
                    onChanged: (_) {
                      controller.settingsController.value
                          .switchNotificationFailure();
                      controller.settingsController.refresh();
                      controller.settingsController.value.saveToHive();
                    },
                  )),
              // NOTIFICATION PERMISSION, if not notification permission
              if (!controller.settingsController.value.notificationPermission)
                ListTile(
                  title: const Text("Ask notification permission"),
                  onTap: () async {
                    await PermissionHandler.notificationFullImplementation();
                    await controller.settingsController.value.initSettings();
                    controller.settingsController.refresh();
                    controller.settingsController.value.saveToHive();
                  },
                ),
            ],
          );
        }),
      ),
    );
  }
}
