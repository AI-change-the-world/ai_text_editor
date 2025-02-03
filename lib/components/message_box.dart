import 'package:flutter/material.dart';

class UserMessageBox extends StatelessWidget {
  const UserMessageBox({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Row(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.blue, borderRadius: BorderRadius.circular(20)),
            child: Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
          Expanded(child: Text(message))
        ],
      ),
    );
  }
}
