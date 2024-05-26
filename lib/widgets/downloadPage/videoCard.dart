import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/myColors.dart';

class VideoCard extends StatelessWidget {
  final String title;
  final String image;
  final String subtitle;
  final bool download;
  final bool errorSubtitle;
  final void Function()? cancelDownload;
  final void Function()? deleteVOD;
  final void Function()? copyLink;
  final void Function()? vodData;
  final void Function()? openPath;

  const VideoCard(
      {super.key,
      required this.title,
      required this.image,
      required this.subtitle,
      required this.download,
      this.cancelDownload,
      this.deleteVOD,
      this.copyLink,
      this.openPath,
      this.vodData,
      this.errorSubtitle = false});

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
          color: MyColors.background,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Row(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
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
                              subtitle,
                              style: TextStyle(
                                  color: errorSubtitle
                                      ? Colors.redAccent
                                      : MyColors.greenDownloadPage,
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
                           PopupMenuButton(
                              icon: const Icon(
                                Icons.more_horiz_rounded,
                              ),
                              offset: const Offset(0, 35),
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem(
                                    onTap: openPath,
                                    value: "1",
                                    child: const Row(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Icon(Icons.open_in_new),
                                        ),
                                        Text("Open"),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    onTap: copyLink,
                                    value: "2",
                                    child: const Row(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Icon(Icons.link),
                                        ),
                                        Text("Stream URL"),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    onTap: deleteVOD,
                                    value: "3",
                                    child: const Row(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Icon(Icons.delete),
                                        ),
                                        Text("Delete file"),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: "4",
                                    onTap: vodData,
                                    child: const Row(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Icon(Icons.info),
                                        ),
                                        Text("File Info"),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                            )
                      //  DropdownButtonHideUnderline(
                      //   child: DropdownButton2(
                      //     onChanged: (value) {},
                      //     customButton: const Padding(
                      //       padding: EdgeInsets.all(10),
                      //       child: Icon(
                      //         Icons.more_horiz_rounded,
                      //       ),
                      //     ),
                      //     buttonStyleData: ButtonStyleData(
                      //       decoration: BoxDecoration(
                      //         borderRadius: BorderRadius.circular(180),
                      //       ),
                      //     ),
                      //     dropdownStyleData: DropdownStyleData(
                      //       width: 160,
                      //       padding:
                      //           const EdgeInsets.symmetric(vertical: 6),
                      //       elevation: 2,
                      //       decoration: BoxDecoration(
                      //         borderRadius: BorderRadius.circular(10),
                      //       ),
                      //       offset: const Offset(0, 8),
                      //     ),
                      //

                      ),
                ],
              ),

              // download slider
              download && subtitle[0].isNumericOnly
                  ? Align(
                      alignment: Alignment.bottomLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: (size - 14) *
                            ((int.tryParse(subtitle.substring(
                                        0, subtitle.indexOf("%"))) ??
                                    0) /
                                100),
                        height: 5,
                        decoration: const BoxDecoration(
                            color: MyColors.greenDownloadPage),
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
