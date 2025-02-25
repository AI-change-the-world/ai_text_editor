part of 'roll_embed.dart';

class CustomRollEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Dice(),
    );
  }

  @override
  String get key => customRollEmbedType;
}

class Dice extends StatefulWidget {
  const Dice({super.key});

  @override
  State<Dice> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<Dice> with SingleTickerProviderStateMixin {
  int diceNumber = 1;
  double rotation = 0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  void rollDice() {
    setState(() {
      diceNumber = Random().nextInt(6) + 1;
      rotation += pi * 2; // 旋转 360 度
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: GestureDetector(
      onTap: rollDice,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: rotation * _controller.value,
            child: child,
          );
        },
        child: CustomPaint(
          size: const Size(150, 150),
          painter: DicePainter(diceNumber),
        ),
      ),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class DicePainter extends CustomPainter {
  final int number;
  DicePainter(this.number);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.grey[200]!;
    final double radius = 12;
    final double padding = size.width * 0.2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // 画骰子的正方形
    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    canvas.drawRRect(rect, paint);

    // 画骰子上的点
    final Paint dotPaint = Paint()..color = Colors.black;

    // 预设点的位置
    final List<Offset> dotPositions = {
      1: [center],
      2: [
        Offset(padding, padding),
        Offset(size.width - padding, size.height - padding)
      ],
      3: [
        Offset(padding, padding),
        center,
        Offset(size.width - padding, size.height - padding)
      ],
      4: [
        Offset(padding, padding),
        Offset(size.width - padding, padding),
        Offset(padding, size.height - padding),
        Offset(size.width - padding, size.height - padding),
      ],
      5: [
        Offset(padding, padding),
        Offset(size.width - padding, padding),
        Offset(padding, size.height - padding),
        Offset(size.width - padding, size.height - padding),
        center,
      ],
      6: [
        Offset(padding, padding),
        Offset(size.width - padding, padding),
        Offset(padding, size.height / 2),
        Offset(size.width - padding, size.height / 2),
        Offset(padding, size.height - padding),
        Offset(size.width - padding, size.height - padding),
      ],
    }[number]!;

    // 绘制点
    for (var dot in dotPositions) {
      canvas.drawCircle(dot, radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DicePainter oldDelegate) {
    return oldDelegate.number != number;
  }
}
