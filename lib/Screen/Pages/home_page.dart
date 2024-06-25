import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:netlnk/widget/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // backgroundColor: Colors.black,
          // title: Text('Home Screen'),
          ),
      body: const PostCard(),
    );
  }
}
