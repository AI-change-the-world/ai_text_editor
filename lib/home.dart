import 'package:ai_text_editor/src/rust/api/message_api.dart';
import 'package:ai_text_editor/src/rust/messages.dart';
import 'package:ai_text_editor/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'components/structures/app_body.dart';
import 'components/structures/app_right_body.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> with WindowListener {
  late final stream = normalMessageStream();

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    super.onWindowClose();
    await windowManager.destroy();
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    stream.listen((v) {
      if (v.$2 == MessageType.error) {
        ToastUtils.error(
          null,
          title: "Error",
          description: v.$1,
        );
      } else {
        ToastUtils.sucess(
          null,
          title: "AI Response",
          description: v.$1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 800,
          height: 600,
          child: Row(
            children: [
              Expanded(child: AppBody()),
              AppRightBody(),
            ],
          ),
        ),
      ),
    );
  }
}
