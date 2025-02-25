import 'package:ai_text_editor/notifiers/models_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'model_chip.dart';

class ModelSettingsWidget extends ConsumerStatefulWidget {
  const ModelSettingsWidget({super.key});

  @override
  ConsumerState<ModelSettingsWidget> createState() =>
      _ModelSettingsWidgetState();
}

class _ModelSettingsWidgetState extends ConsumerState<ModelSettingsWidget> {
  late double top;
  @override
  void initState() {
    super.initState();
    top = -800;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        top = 10;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(modelsProvider);
    return Stack(
      children: [
        SizedBox.expand(),
        AnimatedPositioned(
          top: top,
          left: (MediaQuery.of(context).size.width - 720) / 2,
          duration: Duration(milliseconds: 300),
          child: Material(
            borderRadius: BorderRadius.circular(12),
            elevation: 10,
            child: Container(
              height: 500,
              width: 720,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      ...state.models.map((v) => ModelChip(
                            model: v,
                          )),
                      AddModelButton()
                    ],
                  )),
                  SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        Spacer(),
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("Exit"))
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
