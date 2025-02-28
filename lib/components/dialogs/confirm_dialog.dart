import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({super.key, required this.content, this.height = 150});
  final String content;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: EdgeInsets.all(10),
        width: 300,
        height: height,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
        child: Column(
          children: [
            Expanded(child: Text(content)),
            SizedBox(
              height: 30,
              child: Row(
                spacing: 10,
                children: [
                  Spacer(),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4), // 设置圆角半径
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3), // 调整按钮大小
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text("cancel")),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4), // 设置圆角半径
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3), // 调整按钮大小
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text("confirm")),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
