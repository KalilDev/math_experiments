import 'package:flutter/material.dart';
import 'cartesian_plane.dart';
import 'constants_provider.dart';
import 'package:provider/provider.dart';

abstract class CommonMHSWidget extends StatefulWidget {
  @override
  CommonMHSState createState();
}

abstract class CommonMHSState extends State<CommonMHSWidget>
    with TickerProviderStateMixin {
  AnimationController _controller;
  double period;
  double simSpeed;
  List<FunctionDef> defs;

  void startController(double period, double simSpeed) {
    assert(period != null);
    if (period == this.period && simSpeed == this.simSpeed) return;
    final double t = _controller?.value ?? 0;
    if (_controller != null) _controller.dispose();
    _controller = AnimationController(
        vsync: this,
        duration:
            Duration(milliseconds: (period * (1 / simSpeed) * 1000).floor()),
        upperBound: 2.0);
    _controller.value = t;
    _controller.repeat();
    this.period = period;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double getPeriod(ConstantsProvider consts);
  void updateFunctions(ConstantsProvider consts, Brightness b);
  Widget buildRepresentation(ConstantsProvider consts, Brightness b, double t);

  @override
  Widget build(BuildContext context) {
    final ConstantsProvider consts = Provider.of<ConstantsProvider>(context);
    startController(getPeriod(consts), consts.speed);
    updateFunctions(consts, Theme.of(context).brightness);
    return ListView(
      children: <Widget>[
        Text(
          "Period is ${getPeriod(consts).toStringAsFixed(2)}s",
          textAlign: TextAlign.center,
        ),
        AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) => buildRepresentation(
                consts, Theme.of(context).brightness, _controller.value)),
        AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext c, _) => CartesianPlane(
              coords: Rect.fromLTRB(0, consts.Em * 1.01, 2, -consts.Em * 0.01),
              defs: defs,
              currentX: _controller.value,
              aspectRatio: 2,
              lineSize: 4),
        ),
        RaisedButton(
          onPressed: () => _controller.stop(),
          child: Text('Pause'),
        ),
        RaisedButton(
          onPressed: () => _controller.repeat(),
          child: Text('Resume'),
        )
      ],
    );
  }
}
