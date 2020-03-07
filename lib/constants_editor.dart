import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants_provider.dart';

const Map<ThemeMode, IconData> _kThemeIconMap = {
  ThemeMode.light: Icons.brightness_5,
  ThemeMode.dark: Icons.brightness_3,
  ThemeMode.system: Icons.brightness_auto
};

extension on ThemeMode {
  IconData get icon => _kThemeIconMap[this];
}

Widget enumToggleButtons<T>(
        {@required List<T> values,
        T current,
        @required Widget Function(T t) iconBuilder,
        void Function(T t) onPressed}) =>
    ToggleButtons(
        onPressed: (int i) => onPressed(values[i]),
        children: values.map(iconBuilder).toList(),
        isSelected: values.map((T e) => e == current).toList());

void showConstantsEditor(BuildContext c) {
  showModalBottomSheet(
      context: c,
      elevation: 12.0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (BuildContext c) {
        final consts = Provider.of<ConstantsProvider>(c);
        return ListView(children: [
          ListTile(
            title: Text(
                'Spring constant: ${Provider.of<ConstantsProvider>(c).K}N/m'),
            subtitle: Slider(
              value: consts.K,
              onChanged: (d) => consts.K = d,
              max: 500,
              min: 0,
              divisions: 50,
              label: consts.K.toString(),
            ),
            leading: IconButton(
              icon: Icon(Icons.keyboard_arrow_down),
              onPressed: consts.decK,
            ),
            trailing: IconButton(
              icon: Icon(Icons.keyboard_arrow_up),
              onPressed: consts.incK,
            ),
          ),
          ListTile(
            title: Builder(
                builder: (BuildContext c) => Text(
                    'Mechanical energy: ${Provider.of<ConstantsProvider>(c).Em}J')),
            subtitle: Slider(
              value: consts.Em,
              onChanged: (d) => consts.Em = d,
              max: 500,
              min: 0,
              divisions: 50,
              label: consts.Em.toString(),
            ),
            leading: IconButton(
              icon: Icon(Icons.keyboard_arrow_down),
              onPressed: consts.decEm,
            ),
            trailing: IconButton(
              icon: Icon(Icons.keyboard_arrow_up),
              onPressed: consts.incEm,
            ),
          ),
          ListTile(
            title: Builder(
                builder: (BuildContext c) =>
                    Text('Mass: ${Provider.of<ConstantsProvider>(c).M}Kg')),
            subtitle: Slider(
              value: consts.M,
              onChanged: (d) => consts.M = d,
              max: 500,
              min: 0,
              divisions: 50,
              label: consts.M.toString(),
            ),
            leading: IconButton(
              icon: Icon(Icons.keyboard_arrow_down),
              onPressed: consts.decM,
            ),
            trailing: IconButton(
              icon: Icon(Icons.keyboard_arrow_up),
              onPressed: consts.incM,
            ),
          ),
          ListTile(
            title: Text('Simulation speed: ${consts.speed}'),
            subtitle: Slider(
              value: consts.speed,
              onChanged: (d) => consts.speed = d,
              max: 5,
              min: 0,
              label: consts.speed.toString(),
            ),
            leading: IconButton(
              icon: Icon(Icons.keyboard_arrow_down),
              onPressed: consts.decS,
            ),
            trailing: IconButton(
              icon: Icon(Icons.keyboard_arrow_up),
              onPressed: consts.incS,
            ),
          ),
          ListTile(
            title: Text('Theme'),
            subtitle: enumToggleButtons<ThemeMode>(
                onPressed: (ThemeMode t) => consts.theme = t,
                iconBuilder: (ThemeMode t) => Icon(t.icon),
                values: ThemeMode.values,
                current: consts.theme),
          )
        ]);
      });
}
