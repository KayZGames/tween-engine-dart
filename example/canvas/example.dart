library tweenengine.canvasexample;

import 'dart:html';
import 'dart:math';
import 'package:tweenengine/tweenengine.dart';

part 'screen.dart';
part 'accesors.dart';
part 'screens/functions.dart';
part 'screens/simple_tween.dart';
part 'screens/simple_timeline.dart';
part 'screens/repetitions.dart';
part 'screens/waypoints.dart';
part 'screens/main_menu.dart';

void main() {
  var app = ExampleApp("#canvas");
  app.start();

  window.animationFrame.then(app.render);
}

class ExampleApp {
  CanvasElement canvas;
  CanvasRenderingContext2D context;
  DivElement info;
  TweenManager manager;
  num lastUpdate = 0;
  Screen currentTest;

  ExampleApp(String canvasId) {
    this.canvas = querySelector(canvasId);
    this.context = canvas.getContext("2d");
    this.info = querySelector("#info");
    manager = TweenManager();
    context.canvas.onClick.listen((MouseEvent e) {
      currentTest.onClick(e);
    });
    window.onKeyDown.listen((KeyboardEvent e) {
      currentTest.onKeyDown(e);
    });
  }

  void start() {
    Tween.registerAccessor(Vector2, VectorAccessor());
    Tween.registerAccessor(Color, ColorAccessor());
    Tween.combinedAttributesLimit = 4;
    Tween.waypointsLimit = 4;
    setScreen(MainMenu(context));
  }

  void render(num delta) {
    num deltaTime = (delta - lastUpdate) / 1000;
    lastUpdate = delta;

    context.setFillColorRgb(0, 0, 0, 1);
    context.fillRect(0, 0, canvas.width, canvas.height);

    currentTest.render(deltaTime);
    window.animationFrame.then(render);
  }

  void setScreen(Screen screen) {
    if (currentTest != null) currentTest.dispose();

    currentTest = screen
      ..app = this
      ..initialize();
    info.text = currentTest.info;
  }
}
