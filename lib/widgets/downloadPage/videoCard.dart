import 'package:cached_network_image/cached_network_image.dart';
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
      padding: const EdgeInsets.only(top: 20, right: 7, left: 7),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 70,
        ),
        child: Card(
          elevation: 2,
          color: myColors.background,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: [
              SizedBox(
                height: double.infinity,
                child: CachedNetworkImage(
                  width: size * 0.3,
                  imageUrl: image,
                  fit: BoxFit.fitHeight,
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        style: const TextStyle(
                            overflow: TextOverflow.ellipsis, fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            overflow: TextOverflow.ellipsis, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                "data",
                style: TextStyle(overflow: TextOverflow.ellipsis, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
