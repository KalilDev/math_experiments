import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:math_experiments/constants_provider.dart';
import 'package:provider/provider.dart';
import 'work_funcs.dart';
import 'cartesian_plane.dart';
import 'spring_page.dart';
import 'pendulum_page.dart';

final Map<ThemeMode, IconData> modeIconMap = {
  ThemeMode.light: Icons.brightness_5,
  ThemeMode.dark: Icons.brightness_3,
  ThemeMode.system: Icons.brightness_auto
};

void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(ChangeNotifierProvider(
      create: (BuildContext context) => ConstantsProvider(), child: Home()));
}

class Home extends StatelessWidget {
  void showConstantsEditor(BuildContext c) {
    showModalBottomSheet(
        context: c,
        elevation: 12.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
        builder: (BuildContext c) {
          final ConstantsProvider p = Provider.of<ConstantsProvider>(c);
          return ListView(children: [
            ListTile(
              title: Text(
                  'Spring constant: ${Provider.of<ConstantsProvider>(c).K}N/m'),
              subtitle: Slider(
                value: p.K,
                onChanged: (d) => p.K = d,
                max: 500,
                min: 0,
                divisions: 50,
                label: p.K.toString(),
              ),
              leading: IconButton(
                icon: Icon(Icons.keyboard_arrow_down),
                onPressed: p.decK,
              ),
              trailing: IconButton(
                icon: Icon(Icons.keyboard_arrow_up),
                onPressed: p.incK,
              ),
            ),
            ListTile(
              title: Builder(
                  builder: (BuildContext c) => Text(
                      'Mechanical energy: ${Provider.of<ConstantsProvider>(c).Em}J')),
              subtitle: Slider(
                value: p.Em,
                onChanged: (d) => p.Em = d,
                max: 500,
                min: 0,
                divisions: 50,
                label: p.Em.toString(),
              ),
              leading: IconButton(
                icon: Icon(Icons.keyboard_arrow_down),
                onPressed: p.decEm,
              ),
              trailing: IconButton(
                icon: Icon(Icons.keyboard_arrow_up),
                onPressed: p.incEm,
              ),
            ),
            ListTile(
              title: Builder(
                  builder: (BuildContext c) =>
                      Text('Mass: ${Provider.of<ConstantsProvider>(c).M}Kg')),
              subtitle: Slider(
                value: p.M,
                onChanged: (d) => p.M = d,
                max: 500,
                min: 0,
                divisions: 50,
                label: p.M.toString(),
              ),
              leading: IconButton(
                icon: Icon(Icons.keyboard_arrow_down),
                onPressed: p.decM,
              ),
              trailing: IconButton(
                icon: Icon(Icons.keyboard_arrow_up),
                onPressed: p.incM,
              ),
            ),
            ListTile(
              title: Text('Simulation speed: ${p.speed}'),
              subtitle: Slider(
                value: p.speed,
                onChanged: (d) => p.speed = d,
                max: 5,
                min: 0,
                label: p.speed.toString(),
              ),
              leading: IconButton(
                icon: Icon(Icons.keyboard_arrow_down),
                onPressed: p.decS,
              ),
              trailing: IconButton(
                icon: Icon(Icons.keyboard_arrow_up),
                onPressed: p.incS,
              ),
            ),
            ListTile(
              title: Text('Theme'),
              subtitle: ToggleButtons(
                  onPressed: (int i) => p.theme = ThemeMode.values[i],
                  children: ThemeMode.values
                      .map((ThemeMode t) => Icon(modeIconMap[t]))
                      .toList(),
                  isSelected: ThemeMode.values
                      .map((ThemeMode t) => t == p.theme)
                      .toList()),
            )
          ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: Provider.of<ConstantsProvider>(context).theme,
      darkTheme: ThemeData.dark(),
      home: DefaultTabController(
        length: 1, //2,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Movimento Harmônico Simples"),
            actions: <Widget>[
              Builder(
                  builder: (BuildContext context) => IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () => showConstantsEditor(context)))
            ],
            bottom: TabBar(tabs: [
              Tab(
                text: "Mola",
              ),
              /*Tab(
                text: "Pêndulo: TODO",
              )*/
            ]),
          ),
          body: TabBarView(
            children: <Widget>[
              SpringPage(), /*PendulumPage()*/
            ],
          ),
        ),
      ),
    );
  }
}
