import 'package:ai_text_editor/notifiers/app_title_notifier.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:daynightbanner/daynightbanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppTitle extends ConsumerWidget {
  AppTitle({super.key});

  late final List<Color> hourlyColors = generateHourlyColors();
  late final List<Color> hourlyTextColors = generateHourlyTextColors();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appTitleProvider);
    return SizedBox(
      height: 200,
      child: Row(
        spacing: 20,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            width: 400,
            height: 200,
            child: Stack(
              children: [
                DayNightBanner(
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(1)),
                  hour: state.current.hour,
                  // Add more customization properties here
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: hourlyColors[state.current.hour]),
                    child: Text(
                      "${state.current.hour} : ${state.current.minute}",
                      style: TextStyle(
                        fontSize: 20,
                        color: hourlyTextColors[state.current.hour],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: _buildTitle(state),
          ),
        ],
      ),
    );
  }

  List<Color> generateHourlyColors() {
    List<Color> colors = [];

    for (int hour = 0; hour < 24; hour++) {
      if (hour >= 6 && hour < 18) {
        // 白天使用深色系
        colors.add(
            Color.lerp(Colors.blueGrey.shade900, Colors.black, hour / 24)!);
      } else {
        // 夜晚使用浅色系
        colors.add(
            Color.lerp(Colors.yellow.shade200, Colors.white, (hour - 6) / 24)!);
      }
    }

    return colors;
  }

  List<Color> generateHourlyTextColors() {
    List<Color> colors = [];

    for (int hour = 0; hour < 24; hour++) {
      if (hour >= 6 && hour < 18) {
        // 白天使用深色系

        colors.add(
            Color.lerp(Colors.yellow.shade200, Colors.white, (hour - 6) / 24)!);
      } else {
        // 夜晚使用浅色系
        colors.add(
            Color.lerp(Colors.blueGrey.shade900, Colors.black, hour / 24)!);
      }
    }

    return colors;
  }

  Widget _buildTitle(AppTitleState state) {
    return AnimatedOpacity(
      opacity: state.isLoading ? 0 : 1,
      duration: Duration(seconds: 1),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                state.word,
                minFontSize: 20,
                // maxFontSize: 30,
                style: TextStyle(
                  fontFamily: state.region == "中国" ? "song" : null,
                ),
              ),
              Row(
                children: [
                  Spacer(),
                  Text("———— ${state.from}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ))
                ],
              )
            ]),
      ),
    );
  }
}
