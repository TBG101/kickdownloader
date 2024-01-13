import 'package:flutter/material.dart';
import 'package:kickdownloader/myColors.dart';
import 'package:kickdownloader/utilities/logic.dart';
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

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: myColors.btnVariant, width: 2)),
                child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      link,
                    )),
              ),
            ),
            Text("Streamer: $streamer"),
            Text("Title: $title"),
            Text("Stream Date $stramDate"),
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
                  onPressed: () async {
                    await logic.getURL();
                    print(logic.videoData);

                    setState(() {
                      streamer =
                          logic.videoData!["livestream"]["channel"]["slug"];
                      title = logic.videoData!["livestream"]["session_title"];
                      stramDate = logic.videoData!["livestream"]["start_time"]
                          .split(" ")[0];
                        link = 
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
                                value: true,
                                onChanged: (s) {},
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
                                value: true,
                                onChanged: (s) {},
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
              padding: const EdgeInsets.only(top: 10),
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
    );
  }
}
