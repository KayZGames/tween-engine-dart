part of tweenengine.canvasexample;

abstract class Screen {
  final TweenManager _tweenManager = TweenManager();
  CanvasRenderingContext2D context;
  String font;
  ExampleApp app;

  Vector2 vector1, vector2;
  String title = "", info = '';

  Screen(this.context, this.title) {
    font = "normal 16pt arial";
  }

  void onClick(MouseEvent e) {}

  void onKeyDown(KeyboardEvent e) {}

  void initialize();

  void render(num delta) {
    num textX = context.canvas.width * 0.5 - (title.length * 5);
    context.font = this.font;
    context.fillStyle = 'White';
    context.fillText(title, textX, 30);
  }

  void dispose();
}
