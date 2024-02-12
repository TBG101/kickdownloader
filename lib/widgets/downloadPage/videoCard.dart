import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/myColors.dart';

class VideoCard extends StatelessWidget {
  const VideoCard(
      {super.key,
      required this.title,
      required this.image,
      required this.subtitle,
      required this.download,
      this.cancelDownload});

  final String title;
  final String image;
  final String subtitle;
  final bool download;
  final Function()? cancelDownload;

  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(top: 20, right: 7, left: 7),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 80,
        ),
        child: Card(
          elevation: 2,
          color: myColors.background,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Row(
                children: [
                  SizedBox(
                    height: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              subtitle.isNumericOnly ? "$subtitle%" : subtitle,
                              style: TextStyle(
                                  color: myColors.btnPrimary,
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: download
                        ? IconButton(
                            onPressed: cancelDownload,
                            icon: const Icon(Icons.close_rounded),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton2(
                              onChanged: (value) {},
                              customButton: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.more_horiz_rounded,
                                ),
                              ),
                              buttonStyleData: ButtonStyleData(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(180),
                                ),
                              ),
                              dropdownStyleData: DropdownStyleData(
                                width: 160,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                elevation: 2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                offset: const Offset(0, 8),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "1",
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: Icon(Icons.open_in_new),
                                      ),
                                      Text("Open"),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: "2",
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: Icon(Icons.link),
                                      ),
                                      Text("Stream URL"),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: "3",
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: Icon(Icons.delete),
                                      ),
                                      Text("Delete file"),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: "3",
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: Icon(Icons.info),
                                      ),
                                      Text("File Info"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
              download && subtitle.isNumericOnly
                  ? Align(
                      alignment: Alignment.bottomLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width:
                            (size - 14) * ((int.tryParse(subtitle) ?? 0) / 100),
                        height: 5,
                        decoration: BoxDecoration(color: myColors.btnPrimary),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
