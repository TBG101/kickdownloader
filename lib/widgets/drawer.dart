import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/myColors.dart';
import 'package:kickdownloader/pages/settings.dart';
import 'package:kickdownloader/utilities/logic.dart';

class MyDrawer extends GetView<Logic> {
  const MyDrawer({super.key});

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
                Dialog(
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: FlutterLogo(),
                              ),
                              Text(controller.appName,
                                  style: const TextStyle(fontSize: 22)),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Version ${controller.appVersion}",
                                  style: const TextStyle(fontSize: 14),
                                )),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 5.0),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Developed by AlphaDroid",
                                  style: TextStyle(fontSize: 14),
                                )),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                    foregroundColor:
                                        MyColors.greenDownloadPage),
                                onPressed: () {
                                  Get.to(LicensePage(
                                    applicationName: controller.appName,
                                    applicationVersion: controller.appVersion,
                                    applicationLegalese:
                                        "Developed by AlphaDroid",
                                  ));
                                },
                                child: const Text("View License"),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                    foregroundColor:
                                        MyColors.greenDownloadPage),
                                onPressed: () {
                                  Get.back();
                                },
                                child: const Text("Close"),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
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
