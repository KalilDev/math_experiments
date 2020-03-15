import 'package:flutter/material.dart';
import 'package:flutter_cartesian_plane/cartesian_utils.dart';
import 'package:flutter_cartesian_plane/cartesian_widget.dart';
import 'constants_provider.dart';
import 'package:provider/provider.dart';

abstract class CommonMHSWidget extends StatefulWidget {
  @override
  CommonMHSState createState();
}

abstract class CommonMHSState extends State<CommonMHSWidget>
    with TickerProviderStateMixin {
  AnimationController controller;
  double period;
  double simSpeed;
  List<FunctionDef> defs;

  void startController(double period, double simSpeed) {
    assert(period != null);
    if (period == this.period && simSpeed == this.simSpeed) return;
    final t = controller?.value ?? 0;
    final wasAnimating = controller?.isAnimating ?? true;
    if (controller != null) controller.dispose();
    controller = AnimationController(
        vsync: this,
        duration:
            Duration(milliseconds: (period * (1 / simSpeed) * 1000).floor()),
        upperBound: 2.0);
    controller.value = t;
    if (wasAnimating) {
      controller.repeat();
    }
    this.period = period;
    /*controller.addListener(() {
      updateFunctions(Provider.of<ConstantsProvider>(context, listen: false),
          Theme.of(context).brightness);
    });*/
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  double getPeriod(ConstantsProvider consts);
  void updateFunctions(ConstantsProvider consts, Brightness b);
  Widget buildRepresentation(ConstantsProvider consts, Brightness b, double t);
  Rect getCoords(ConstantsProvider consts);

  @override
  Widget build(BuildContext context) {
    final consts = Provider.of<ConstantsProvider>(context);
    startController(getPeriod(consts), consts.speed);
    updateFunctions(consts, Theme.of(context).brightness);
    return ListView(
      children: <Widget>[
        Text(
          'Period is ${getPeriod(consts).toStringAsFixed(2)}s',
          textAlign: TextAlign.center,
        ),
        AnimatedBuilder(
            animation: controller,
            builder: (BuildContext context, _) => buildRepresentation(
                consts, Theme.of(context).brightness, controller.value)),
        AnimatedBuilder(
          animation: controller,
          builder: (BuildContext c, _) => CartesianPlane(
              coords: getCoords(consts),
              defs: defs,
              currentX: controller.value,
              aspectRatio: 2,
              lineSize: 3),
        ),
        if (controller.isAnimating)
          RaisedButton(
            onPressed: () {
              controller.stop();
              setState(() => null);
            },
            child: Text('Pause'),
          ),
        if (!controller.isAnimating)
          RaisedButton(
            onPressed: () {
              controller.repeat();
              setState(() => null);
            },
            child: Text('Resume'),
          )
      ],
    );
  }
}
