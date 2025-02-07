import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GradientTweenPage(),
    );
  }
}

class GradientTweenPage extends StatefulWidget {
  const GradientTweenPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _GradientTweenPageState createState() => _GradientTweenPageState();
}

class _GradientTweenPageState extends State<GradientTweenPage> {
  double animationValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("渐变动画")),
      body: Center(
        child: GestureDetector(
          onTap: () {
            setState(() {
              animationValue = animationValue == 0.0 ? 1.0 : 0.0;
            });
          },
          child: TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween<double>(begin: 0.0, end: animationValue),
            builder: (context, value, child) {
              return Container(
                width: 300,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0, value, 1],
                    colors: [
                      // Color.lerp(Colors.blue, Colors.red, value)!,
                      Colors.blue,
                      // ignore: deprecated_member_use
                      Colors.blue.withOpacity(0),
                      Colors.blue,
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "点击变色",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
