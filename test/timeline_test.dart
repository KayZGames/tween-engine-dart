import 'dart:async';
import 'package:test/test.dart';
import 'package:tweenengine/tweenengine.dart';

/// Fixture [TweenAccessor] for tests
class MyAccessor implements TweenAccessor<MyClass> {
  static const int xy = 1;

  int getValues(
      MyClass target, Tween tween, int tweenType, List<num> returnValues) {
    if (tweenType == MyAccessor.xy) {
      returnValues[0] = target.x;
      returnValues[1] = target.y;
      return 2;
    }
    return 0;
  }

  void setValues(
      MyClass target, Tween tween, int tweenType, List<num> newValues) {
    if (tween.userData is String) {
      if (tween.userData == 'time') {
        print('normal time: ${tween.normalTime}');
        print('currentTime time: ${tween.currentTime}');
      }
    }

    if (tweenType == MyAccessor.xy) {
      target.x = newValues[0];
      target.y = newValues[1];
    }
  }
}

/// Fixture class for tests (/!\ MUST HAVE VALUES)
class MyClass {
  num x = 0, y = 0;
  int n = 0;
}

void main() {
  TweenManager myManager;
  Stopwatch watch;
  Timer timer;
  Tween.registerAccessor(MyClass, MyAccessor());

  setUp(() {
    myManager = TweenManager();
    watch = Stopwatch();

    var ticker = (timer) {
      var deltaInSeconds = watch.elapsedMilliseconds / 1000;

      myManager.update(deltaInSeconds);
      watch.reset();
    };

    var duration = Duration(milliseconds: 1000 ~/ 60);
    watch.start();
    timer = Timer.periodic(duration, ticker);
  });

  tearDown(() {
    timer.cancel();
    watch.stop();
  });

  // TEST
  group('Normalized time', () {
    test('for normal sequence', () {
      var myClass = MyClass();

      Function expectOnBegin = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, equals(0));
      });

      Function expectOnStart = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, lessThan(1));
      });

      Function expectOnEnd = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, greaterThan(0));
      });

      Function expectOnComplete = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, equals(1));
      });

      TweenCallbackHandler myCallback = (type, tween) {
        switch (type) {
          case TweenCallback.begin:
            expectOnBegin(tween);
            break;
          case TweenCallback.complete:
            expectOnComplete(tween);
            break;
          case TweenCallback.start:
            expectOnStart(tween);
            break;
          case TweenCallback.end:
            expectOnEnd(tween);
            break;
          default:
            print('DEFAULT CALLBACK CAUGHT ; type = ' + type.toString());
        }
      };

      Timeline.sequence()
        ..push(Tween.to(myClass, 1, 0.1)..targetValues = [20, 20])
        ..push(Tween.to(myClass, 1, 0.1)..targetValues = [40, 40])
        ..callback = myCallback
        ..callbackTriggers = TweenCallback.any
        ..userData = 'time'
        ..start(myManager);
    });

    test('for normal parallel', () {
      var myClass = MyClass();

      Function expectOnBegin = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, equals(0));
      });

      Function expectOnStart = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, lessThan(1));
      });

      Function expectOnEnd = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, greaterThan(0));
      });

      Function expectOnComplete = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, equals(1));
      });

      TweenCallbackHandler myCallback = (type, tween) {
        switch (type) {
          case TweenCallback.begin:
            expectOnBegin(tween);
            break;
          case TweenCallback.complete:
            expectOnComplete(tween);
            break;
          case TweenCallback.start:
            expectOnStart(tween);
            break;
          case TweenCallback.end:
            expectOnEnd(tween);
            break;
          default:
            print('DEFAULT CALLBACK CAUGHT ; type = ' + type.toString());
        }
      };

      Timeline.parallel()
        ..push(Tween.to(myClass, 1, 0.1)..targetValues = [20, 20])
        ..push(Tween.to(myClass, 1, 0.12)..targetValues = [40, 40])
        ..callback = myCallback
        ..callbackTriggers = TweenCallback.any
        ..userData = 'time'
        ..start(myManager);
    });

    test('for repeat sequence', () {
      var myClass = MyClass();

      Function expectOnBegin = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, equals(0));
      });

      Function expectOnStart = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, lessThan(1));
      }, count: 2);

      Function expectOnEnd = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, greaterThan(0));
      }, count: 2);

      Function expectOnComplete = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, equals(1));
      });

      TweenCallbackHandler myCallback = (type, tween) {
        switch (type) {
          case TweenCallback.begin:
            expectOnBegin(tween);
            break;
          case TweenCallback.complete:
            expectOnComplete(tween);
            break;
          case TweenCallback.start:
            expectOnStart(tween);
            break;
          case TweenCallback.end:
            expectOnEnd(tween);
            break;
          default:
            print('DEFAULT CALLBACK CAUGHT ; type = ' + type.toString());
        }
      };

      Timeline.sequence()
        ..push(Tween.to(myClass, 1, 0.1)..targetValues = [20, 20])
        ..push(Tween.to(myClass, 1, 0.1)..targetValues = [40, 40])
        ..callback = myCallback
        ..callbackTriggers = TweenCallback.any
        ..userData = 'time'
        ..repeat(1, 0)
        ..start(myManager);
    });

    test('for repeat parallel', () {
      var myClass = MyClass();

      Function expectOnBegin = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, equals(0));
      });

      Function expectOnStart = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, lessThan(1));
      }, count: 2);

      Function expectOnEnd = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, greaterThan(0));
      }, count: 2);

      Function expectOnComplete = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, equals(1));
      });

      TweenCallbackHandler myCallback = (type, tween) {
        switch (type) {
          case TweenCallback.begin:
            expectOnBegin(tween);
            break;
          case TweenCallback.complete:
            expectOnComplete(tween);
            break;
          case TweenCallback.start:
            expectOnStart(tween);
            break;
          case TweenCallback.end:
            expectOnEnd(tween);
            break;
          default:
            print('DEFAULT CALLBACK CAUGHT ; type = ' + type.toString());
        }
      };

      Timeline.parallel()
        ..push(Tween.to(myClass, 1, 0.1)..targetValues = [20, 20])
        ..push(Tween.to(myClass, 1, 0.13)..targetValues = [40, 40])
        ..callback = myCallback
        ..callbackTriggers = TweenCallback.any
        ..userData = 'time'
        ..repeat(1, 0)
        ..start(myManager);
    });

    test('for repeat yoyo sequence', () {
      var myClass = MyClass();

      Function expectOnBegin = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, equals(0));
      });

      Function expectOnStart = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, lessThan(1));
      }, count: 2);

      Function expectOnEnd = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, greaterThan(0));
      }, count: 2);

      Function expectOnComplete = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, equals(1));
      });

      TweenCallbackHandler myCallback = (type, tween) {
        switch (type) {
          case TweenCallback.begin:
            expectOnBegin(tween);
            break;
          case TweenCallback.complete:
            expectOnComplete(tween);
            break;
          case TweenCallback.start:
            expectOnStart(tween);
            break;
          case TweenCallback.end:
            expectOnEnd(tween);
            break;
          default:
            print('DEFAULT CALLBACK CAUGHT ; type = ' + type.toString());
        }
      };

      Timeline.sequence()
        ..push(Tween.to(myClass, 1, 0.1)..targetValues = [20, 20])
        ..push(Tween.to(myClass, 1, 0.1)..targetValues = [40, 40])
        ..callback = myCallback
        ..callbackTriggers = TweenCallback.any
        ..userData = 'time'
        ..repeatYoyo(1, 0)
        ..start(myManager);
    });

    test('for repeat yoyo parallel', () {
      var myClass = MyClass();

      Function expectOnBegin = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, equals(0));
      });

      Function expectOnStart = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, lessThan(1));
      }, count: 2);

      Function expectOnEnd = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, greaterThan(0));
      }, count: 2);

      Function expectOnComplete = expectAsync1((BaseTween tween) {
        expect(tween.normalTime, equals(1));
      });

      TweenCallbackHandler myCallback = (type, tween) {
        switch (type) {
          case TweenCallback.begin:
            expectOnBegin(tween);
            break;
          case TweenCallback.complete:
            expectOnComplete(tween);
            break;
          case TweenCallback.start:
            expectOnStart(tween);
            break;
          case TweenCallback.end:
            expectOnEnd(tween);
            break;
          default:
            print('DEFAULT CALLBACK CAUGHT ; type = ' + type.toString());
        }
      };

      Timeline.parallel()
        ..push(Tween.to(myClass, 1, 0.1)..targetValues = [20, 20])
        ..push(Tween.to(myClass, 1, 0.13)..targetValues = [40, 40])
        ..callback = myCallback
        ..callbackTriggers = TweenCallback.any
        ..userData = 'time'
        ..repeatYoyo(1, 0)
        ..start(myManager);
    });
  });

  group('Other', () {
    test('-killing timeline from within a child tween', () {
      var myObj = MyClass();
      num killedByTween = -1;
      Timeline rootTimeline;

      Function timelineElapsedLessThan1 = expectAsync0(() {
        //this  function should only  be called by first tween
        expect(killedByTween, equals(1));
        expect(rootTimeline.currentTime, lessThan(1));
      });

      TweenCallbackHandler killTimeline = (int type, BaseTween tween) {
        killedByTween = tween.userData as num;
        rootTimeline.kill();
        timelineElapsedLessThan1();
      };

      rootTimeline = Timeline.sequence()
        ..beginParallel()
        ..push(Tween.to(myObj, 1, 0.9)
          ..targetRelative = [5, 5]
          ..userData = 1
          ..callback = killTimeline
          ..callbackTriggers = TweenCallback.complete)
        ..push(Tween.to(myObj, 1, 1.3)
          ..targetRelative = [5, 5]
          ..userData = 2
          ..callback = killTimeline
          ..callbackTriggers = TweenCallback.complete)
        ..end()
        ..push(Tween.to(myObj, 1, 1)
          ..targetRelative = [5, 5]
          ..userData = 3
          ..callback = killTimeline
          ..callbackTriggers = TweenCallback.complete)
        ..start(myManager);
    });
  });
}
