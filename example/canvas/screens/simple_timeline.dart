part of tweenengine.canvasexample;

class SimpleTimeline extends Screen{
  Vector2 pos, size;
  Color color;
  
  SimpleTimeline(CanvasRenderingContext2D context): super(context, "Simple Timeline");
  
  initialize(){
    
    pos = new Vector2(); size = new Vector2();
    color = new Color();
    
    this.info = """A 'timeline' sequences multiple tweens (or other timelines)
        either one after the other, or all at once. Press escape to go back""";
    
    new Timeline.sequence()
      ..push(new Tween.set(pos, VectorAccessor.XY)..targetValues = [100, 100])
      ..push(new Tween.set(size, VectorAccessor.XY)..targetValues = [30, 30])
      ..push(new Tween.set(color, ColorAccessor.RGBA)..targetValues = [255, 255, 0, 1])
      ..beginParallel()
        ..push(new Tween.to(pos, VectorAccessor.XY, 1)..targetRelative = [200, 80])
        ..push(new Tween.to(size, VectorAccessor.XY, 1)..targetRelative = [50, 0])
        ..push(new Tween.to(color, ColorAccessor.RGB, 1)..targetRelative = [-255, 0, 0] )
      ..end()
      ..beginParallel()
        ..push(new Tween.to(pos, VectorAccessor.XY, 1)..targetRelative = [-100, 80])
        ..push(new Tween.to(size, VectorAccessor.XY, 1)..targetRelative = [-50, 20])
        ..push(new Tween.to(color, ColorAccessor.RGB, 1)..targetRelative = [0, -255, 0] )
      ..end()
      ..push(new Tween.to(color, ColorAccessor.RGBA, 1)..targetValues = [255, 255, 255, 0] )
      ..repeat(Tween.INFINITY, 0.5)
      ..start(_tweenManager);
      
  }
  
  render(num delta){
    super.render(delta);
    _tweenManager.update(delta);    
    context
      ..beginPath()
      ..rect(pos.x, pos.y, size.x, size.y)
      ..setFillColorRgb(color.r.toInt(), color.g.toInt(), color.b.toInt(), color.a)
      ..fill()
      ..lineWidth = 2
      ..setStrokeColorRgb(255, 255, 255, color.a)
      ..stroke();
  }
  
  void onKeyDown(KeyboardEvent e){
    if (e.keyCode == KeyCode.ESC){
      app.setScreen(new MainMenu(context));
      dispose();
    }
  }
  
  dispose(){
    _tweenManager.killAll();
  }
  
}