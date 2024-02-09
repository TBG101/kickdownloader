import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';

class myDrawer extends GetView<Logic> {
  const myDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            onTap: () {
              controller.pageSelector.value = 0;
            },
            title: const Text("VOD donwloader"),
          ),
          ListTile(
            onTap: () {
              controller.pageSelector.value = 0;
            },
            title: const Text("Clip Downloader"),
          )
        ],
      ),
    );
  }
}
