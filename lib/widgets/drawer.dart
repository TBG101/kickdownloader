import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/pages/settings.dart';
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
            leading: const Icon(Icons.info_outline_rounded),
            onTap: () {
              Get.dialog(
                AboutDialog(
                  applicationVersion: controller.appVersion,
                  applicationIcon: const FlutterLogo(),
                  applicationLegalese: "Developed by AlphaDroid",
                ),
              );
            },
            title: const Text("Versions"),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            onTap: () {},
            title: const Text("Upgrade to premium"),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            onTap: () {
              Get.to(const Settings());
              Scaffold.of(context).closeDrawer();
            },
            title: const Text("Settings"),
          ),
        ],
      ),
    );
  }
}
