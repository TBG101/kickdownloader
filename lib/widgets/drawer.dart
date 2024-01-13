import 'package:flutter/material.dart';

class myDrawer extends StatelessWidget {
  const myDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            onTap: () {},
            title: const Text("VOD donwloader"),
          ),
          ListTile(
            onTap: () {},
            title: const Text("Clip Downloader"),
          )
        ],
      ),
    );
  }
}
