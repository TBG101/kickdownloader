import 'package:flutter/material.dart';
import 'package:kickdownloader/myColors.dart';

class VideoCard extends StatelessWidget {
  const VideoCard(
      {super.key,
      required this.title,
      required this.image,
      required this.subtitle});

  final String title;
  final String image;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Card(
        elevation: 2,
        color: myColors.background,
        margin: const EdgeInsets.all(5),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: size * 0.3,
          ),
          child: ListTile(
            title: Text(title),
            leading: Text("image"),
            subtitle: Text(subtitle),
            trailing: Text("data"),
          ),
        ),
      ),
    );
  }
}
