import 'package:mass_finder/mass_finder_screen.dart';
import 'package:flutter/material.dart';

void main() async {
  runApp(MyApp());
}
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        ScreenEnum.aminoCalc.route: (_) => const MassFinderScreen(),
      },
    );
  }
}

enum ScreenEnum{
  aminoCalc('/', '아미노산 계산기');

  final String route;
  final String name;
  const ScreenEnum(this.route, this.name);

}
