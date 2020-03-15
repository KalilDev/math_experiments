import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:math_experiments/constants_provider.dart';
import 'constants_editor.dart';
import 'package:provider/provider.dart';
import 'spring_page.dart';
import 'pendulum_page.dart';

void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  //runApp(Benchmark());
  runApp(ChangeNotifierProvider(
      create: (BuildContext context) => ConstantsProvider(), child: Home()));
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: Provider.of<ConstantsProvider>(context).theme,
      darkTheme: ThemeData.dark(),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Movimento Harmônico Simples'),
            actions: <Widget>[
              Builder(
                  builder: (BuildContext context) => IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () => showConstantsEditor(context)))
            ],
            bottom: TabBar(tabs: [
              Tab(
                text: 'Mola',
              ),
              Tab(
                text: 'Pêndulo: TODO',
              )
            ]),
          ),
          body: TabBarView(
            children: <Widget>[SpringPage(), PendulumPage()],
          ),
        ),
      ),
    );
  }
}
