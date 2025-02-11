import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: AnimatedListExample()));
}

class AnimatedListExample extends StatefulWidget {
  const AnimatedListExample({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AnimatedListExampleState createState() => _AnimatedListExampleState();
}

class _AnimatedListExampleState extends State<AnimatedListExample> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<String> _items = List.generate(5, (index) => 'Item ${index + 1}');

  void _removeItem(int index) {
    final removedItem = _items[index];

    _listKey.currentState!.removeItem(
      index,
      (context, animation) => _buildFadeOutItem(removedItem, animation),
      duration: Duration(milliseconds: 500), // 设置淡出时长
    );

    _items.removeAt(index);
  }

  // 渐隐淡出动画
  Widget _buildFadeOutItem(String item, Animation<double> animation) {
    return FadeTransition(
      opacity: animation, // 让 item 渐渐消失
      child: Card(
        child: ListTile(
          title: Text(item),
        ),
      ),
    );
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    return FadeTransition(
      opacity: animation, // 让新 item 渐入
      child: Card(
        child: ListTile(
          title: Text(_items[index]),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeItem(index),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Animated List - Fade Out")),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _items.length,
        itemBuilder: _buildItem,
      ),
    );
  }
}
