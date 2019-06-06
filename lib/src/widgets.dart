import 'dart:io';

import 'package:fake_lifecycle/src/tracker.dart';
import 'package:flutter/widgets.dart';

class LifecycleWidget extends StatefulWidget {
  LifecycleWidget({
    Key key,
    @required this.tracker,
    @required this.child,
  })  : assert(tracker != null),
        assert(child != null),
        super(key: key);

  final LifecycleTracker tracker;
  final Widget child;

  @override
  State<StatefulWidget> createState() {
    return _LifecycleWidgetState();
  }
}

class _LifecycleWidgetState extends State<LifecycleWidget>
    with WidgetsBindingObserver {
  bool _lifeResumed = false;
  bool _shouldPopSystem = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Future<bool> didPopRoute() {
    return super.didPopRoute().then((bool result) {
      if (!result) {
        Route<dynamic> route = ModalRoute.of<dynamic>(context);
        if (route.isFirst) {
          _shouldPopSystem = true;
          widget.tracker.trackPauseRoute(route: route);
          widget.tracker.trackStopRoute(route: route);
        }
      }
      return result;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    Route<dynamic> route = ModalRoute.of<dynamic>(context);
    if (route.isCurrent) {
      if (state == AppLifecycleState.resumed) {
        /// release 启动首页时候，会先调用一次 resumed
        if (Platform.isAndroid) {
          if (!_isReleaseMode() || !route.isFirst || _lifeResumed) {
            widget.tracker.trackResumeRoute(route: route);
          }
        } else {
          widget.tracker.trackResumeRoute(route: route);
        }
        _lifeResumed = true;
      } else if (state == AppLifecycleState.paused) {
        if (!_shouldPopSystem) {
          widget.tracker.trackPauseRoute(route: route);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  bool _isReleaseMode() {
    return const bool.fromEnvironment('dart.vm.product');
  }
}
