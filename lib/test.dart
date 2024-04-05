import 'package:flutter/material.dart';

class ClassicPage extends StatefulWidget {
  final test_param;
  const ClassicPage({Key? key,required this.test_param}) : super(key: key);

  @override
  State<ClassicPage> createState() => _ClassicPageState();
}

class _ClassicPageState extends State<ClassicPage> {

  @override
  void initState() {
    print("Params "+widget.test_param.toString());
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Yo"),
      ),
    );
  }
}
