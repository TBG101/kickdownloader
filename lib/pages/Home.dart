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
  double gradientOpacity = 0.4;
  bool startValue = false;
  bool endValue = false;
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
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: StreamFields(field: "Streamer", text: streamer),
              ),
              StreamFields(field: "Tile", text: title),
              StreamFields(field: "Stream date", text: stramDate),
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: logic.url,
                    decoration: const InputDecoration(
                        hintText: "Stream URL", border: OutlineInputBorder()),
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5))),
                    onPressed: () {
                      logic.getURL().then((_) {
                        setState(() {
                          streamer =
                              logic.videoData!["livestream"]["channel"]["slug"];
                          title =
                              logic.videoData!["livestream"]["session_title"];
                          stramDate = logic.videoData!["livestream"]
                                  ["start_time"]
                              .split(" ")[0];
                          link = logic.thumbnailLink();
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
                        value: "1",
                        iconEnabledColor: myColors.white,
                        isExpanded:
                            true, //make true to take width of parent widget
                        underline: Container(), //empty line
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                        items: const [
                          DropdownMenuItem(
                              value: "1", child: Text("Video Quality")),
                          DropdownMenuItem(value: "2", child: Text("720p")),
                          DropdownMenuItem(value: "3", child: Text("480p")),
                          DropdownMenuItem(value: "4", child: Text("360p")),
                        ],
                        onChanged: (Object? value) {},
                      ),
                    ),
                  )),
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
                                    setState(() {
                                      startValue = !startValue;
                                    });
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                            ]),
                      ),
                      const SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            VideoTimeWidget(text: "H"),
                            VideoTimeWidget(text: "S", padLeft: 9),
                            VideoTimeWidget(text: "M", padLeft: 9),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
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
                                    setState(() {
                                      endValue = !endValue;
                                    });
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                            ]),
                      ),
                      const SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            VideoTimeWidget(text: "H"),
                            VideoTimeWidget(text: "S", padLeft: 9),
                            VideoTimeWidget(text: "M", padLeft: 9),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0, bottom: 10),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5))),
                      onPressed: () {},
                      child: const Text(
                        "Download VOD",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
