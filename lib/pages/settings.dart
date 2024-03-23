import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/myColors.dart';
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
        body: ListView(
          children: [
            const ListTile(
              title: Text("Language"),
              subtitle: Text("English (more coming soon)"),
            ),
            const Divider(),
            ListTile(
              title: const Text("Save path"),
              subtitle:
                  Text(controller.selectedDirectory.value ?? "No save path"),
              onTap: () {},
            ),
            ListTile(
                title: const Text("Ask Download Folder"),
                subtitle: const Text(
                    "Ask where to download everytime you download a new VOD"),
                trailing: Switch(
                  activeColor: MyColors.greenDownloadPage,
                  value: false,
                  onChanged: (_) {},
                )),
            ListTile(
              title: const Text("Ask storage permission"),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
                title: const Text("Notifications"),
                subtitle: const Text("Enable or disable notifications"),
                trailing: Switch(
                  activeColor: MyColors.greenDownloadPage,
                  value: true,
                  onChanged: (_) {},
                )),
            ListTile(
                title: const Text("Notifications notify on complete"),
                trailing: Switch(
                  activeColor: MyColors.greenDownloadPage,
                  value: true,
                  onChanged: (_) {},
                )),
            ListTile(
                title: const Text("Notifications notify on failure"),
                trailing: Switch(
                  activeColor: MyColors.greenDownloadPage,
                  value: true,
                  onChanged: (_) {},
                )),
            ListTile(
              title: const Text("Ask notification permission"),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
