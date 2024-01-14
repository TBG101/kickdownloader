import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_network/image_network.dart';
import 'package:kickdownloader/myColors.dart';
import 'package:kickdownloader/utilities/logic.dart';
import 'package:kickdownloader/widgets/drawer.dart';
import 'package:kickdownloader/widgets/streamFields.dart';
import 'package:kickdownloader/widgets/videoTimeWidget.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String link =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Aspect_ratio_-_16x9.svg/1200px-Aspect_ratio_-_16x9.svg.png";
  Logic logic = Logic();
  String streamer = "";
  String title = "";
  String stramDate = "";
  String streamLength = "";
  double gradientOpacity = 0.4;
  bool startValue = false;
  bool endValue = false;
  String? valueSelected;

  // text controllers
  TextEditingController startHour = TextEditingController();
  TextEditingController startMinute = TextEditingController();
  TextEditingController startSecond = TextEditingController();
  TextEditingController endHour = TextEditingController();
  TextEditingController endMinute = TextEditingController();
  TextEditingController endSecond = TextEditingController();

  List<DropdownMenuItem<String>> listitemButton() {
    if (logic.resolutions.isEmpty) return [];
    List<DropdownMenuItem<String>> e = [];
    logic.resolutions.forEach((element) {
      e.add(DropdownMenuItem(
        value: element,
        child: Text(element),
      ));
    });
    return e;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Scaffold(
          drawer: const myDrawer(),
          appBar: AppBar(
            actions: [
              IconButton(
                  onPressed: () {}, icon: const Icon(Icons.download_rounded))
            ],
            title: const Text("Kick Downloader VOD"),
            backgroundColor: myColors.btnPrimary,
            elevation: 1,
            centerTitle: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              // STREAM THUMBNAIL
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x00000000)
                            .withOpacity(gradientOpacity),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                        spreadRadius: 1,
                      )
                    ]),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      link,
                      fit: BoxFit.contain,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          gradientOpacity = 0.4;
                          return child;
                        }
                        gradientOpacity = 0;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // TEXT FOR STREAM FIELDS
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: StreamFields(field: "Streamer", text: streamer),
              ),
              StreamFields(field: "Tile", text: title),
              StreamFields(field: "Stream date", text: stramDate),
              StreamFields(field: "Stream Length", text: streamLength),
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: logic.url,
                    decoration: const InputDecoration(
                        hintText: "Stream URL", border: OutlineInputBorder()),
                  )),
              // GET VOD DATA BUTTON

              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5))),
                    onPressed: () {
                      setState(() {
                        logic.foundVideo = false;
                      });
                      logic.getURL().then((_) async {
                        await logic.getVidQuality();
                        print(logic.resolutions);

                        var duration = Duration(
                            hours: 0,
                            seconds: 0,
                            minutes: 0,
                            milliseconds: logic.videoData!["livestream"]
                                ["duration"] as int);

                        setState(() {
                          streamer =
                              logic.videoData!["livestream"]["channel"]["slug"];
                          title =
                              logic.videoData!["livestream"]["session_title"];
                          stramDate = logic.videoData!["livestream"]
                                  ["start_time"]
                              .split(" ")[0];
                          streamLength = duration.toString().split('.')[0];

                          link = logic.thumbnailLink();
                          valueSelected = logic.resolutions[0];
                          print(logic.videoData);
                        });
                      });
                    },
                    child: const Text(
                      "Get VOD data",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              // QUALITY SELECTOR DROPDOWN

              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: myColors.btnPrimary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: DropdownButton<String>(
                        elevation: 2,
                        disabledHint: const Text("Video Quality"),
                        value: valueSelected,
                        iconEnabledColor: myColors.white,
                        isExpanded:
                            true, //make true to take width of parent widget
                        underline: Container(), //empty line
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                        items: listitemButton(),

                        onChanged: (Object? value) {
                          setState(() {
                            valueSelected = value as String;
                          });
                        },
                      ),
                    ),
                  )),

              // START ROW FOR THE TIME SELECTOR
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  height: 80,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: size.width * 0.24,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "Start",
                                style: TextStyle(fontSize: 17),
                              ),
                              Transform.scale(
                                scale: 1.2,
                                child: Checkbox(
                                  value: startValue,
                                  onChanged: (s) {
                                    if (logic.foundVideo == true) {
                                      setState(() {
                                        startValue = !startValue;
                                      });
                                    } else {
                                      setState(() {
                                        startValue = false;
                                      });
                                    }
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                            ]),
                      ),
                      SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            VideoTimeWidget(
                              text: "H",
                              enable: logic.foundVideo && startValue,
                              controller: startHour,
                            ),
                            VideoTimeWidget(
                              text: "S",
                              padLeft: 9,
                              enable: logic.foundVideo && startValue,
                              controller: startMinute,
                            ),
                            VideoTimeWidget(
                              text: "M",
                              padLeft: 9,
                              enable: logic.foundVideo && startValue,
                              controller: startSecond,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // END ROW FOR THE TIME SELECTOR
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  height: 80,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.24,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "End",
                                style: TextStyle(fontSize: 17),
                              ),
                              Transform.scale(
                                scale: 1.2,
                                child: Checkbox(
                                  value: endValue,
                                  onChanged: (s) {
                                    if (logic.foundVideo == true) {
                                      setState(() {
                                        endValue = !endValue;
                                      });
                                    } else {
                                      setState(() {
                                        endValue = false;
                                      });
                                    }
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                            ]),
                      ),
                      SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            VideoTimeWidget(
                              text: "H",
                              enable: logic.foundVideo && endValue,
                              controller: endHour,
                            ),
                            VideoTimeWidget(
                              text: "S",
                              padLeft: 9,
                              enable: logic.foundVideo && endValue,
                              controller: endMinute,
                            ),
                            VideoTimeWidget(
                              text: "M",
                              padLeft: 9,
                              enable: logic.foundVideo && endValue,
                              controller: endSecond,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              //  DOWNLOAD VOD BUTTON

              Padding(
                padding: const EdgeInsets.only(top: 0, bottom: 10),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5))),
                    onPressed: () {
                      if (logic.foundVideo) {
                        logic.downloadVOD(valueSelected!);
                      }
                    },
                    child: const Text(
                      "Download VOD",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
