import 'package:flutter/material.dart';

class VideoCard extends StatelessWidget {
  const VideoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      title: Text("title"),
      leading: Text("image"),
      subtitle: Text("subtitle"),
      trailing: Text("data"),
    );
  }
}
