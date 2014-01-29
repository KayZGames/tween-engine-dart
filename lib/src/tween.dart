part of tweenengine;

/**
 * Core class of the Tween Engine. A Tween is basically an interpolation
 * between two values of an object attribute. However, the main interest of a
 * Tween is that you can apply an easing formula on this interpolation, in
 * order to smooth the transitions or to achieve cool effects like springs or
 * bounces.
 * <p/>
 *
 * The Universal Tween Engine is called "universal" because it is able to apply
 * interpolations on every attribute from every possible object. Therefore,
 * every object in your application can be animated with cool effects: it does
 * not matter if your application is a game, a desktop interface or even a
 * console program! If it makes sense to animate something, then it can be
 * animated through this engine.
 * <p/>
 *
 * This class contains many static factory methods to create and instantiate
 * new interpolations easily. The common way to create a Tween is by using one
 * of these factories:
 * <p/>
 *
 * - Tween.to(...)<br/>
 * - Tween.from(...)<br/>
 * - Tween.set(...)<br/>
 * - Tween.call(...)
 * <p/>
 *
 * <h2>Example - firing a Tween</h2>
 *
 * The following example will move the target horizontal position from its
 * current value to x=200 and y=300, during 500ms, but only after a delay of
 * 1000ms. The animation will also be repeated 2 times (the starting position
 * is registered at the end of the delay, so the animation will automatically
 * restart from this registered position).
 * <p/>
 *
 * <pre> {@code
 * Tween.to(myObject, POSITION_XY, 0.5f)
 *      .target(200, 300)
 *      .ease(Quad.INOUT)
 *      .delay(1.0f)
 *      .repeat(2, 0.2f)
 *      .start(myManager);
 * }</pre>
 *
 * Tween life-cycles can be automatically managed for you, thanks to the
 * {@link TweenManager} class. If you choose to manage your tween when you start
 * it, then you don't need to care about it anymore. <b>Tweens are
 * <i>fire-and-forget</i>: don't think about them anymore once you started
 * them (if they are managed of course).</b>
 * <p/>
 *
 * You need to periodicaly update the tween engine, in order to compute the new
 * values. If your tweens are managed, only update the manager; else you need
 * to call {@link #update()} on your tweens periodically.
 * <p/>
 *
 * <h2>Example - setting up the engine</h2>
 *
 * The engine cannot directly change your objects attributes, since it doesn't
 * know them. Therefore, you need to tell him how to get and set the different
 * attributes of your objects: <b>you need to implement the {@link
 * TweenAccessor} interface for each object class you will animate</b>. Once
 * done, don't forget to register these implementations, using the static method
 * {@link registerAccessor()}, when you start your application.
 *
 * @see TweenAccessor
 * @see TweenManager
 * @see TweenEquation
 * @see Timeline
 * @author Aurelien Ribon | http://www.aurelienribon.com/
 */
class Tween extends BaseTween<Tween> {
  // -------------------------------------------------------------------------
  // Static -- misc
  // -------------------------------------------------------------------------

  ///Used as parameter in [repeat] and [repeatYoyo] methods.
  static const int INFINITY = -1;

  static int _combinedAttrsLimit = 3;
  static int _waypointsLimit = 0;

  ///Changes the [limit] for combined attributes. Defaults to 3 to reduce memory footprint.
  static void setCombinedAttributesLimit(int limit) { 
    Tween._combinedAttrsLimit = limit; 
  }

  ///Changes the [limit] of allowed waypoints for each tween. Defaults to 0 to reduce memory footprint.
  static void setWaypointsLimit(int limit){ 
    Tween._waypointsLimit = limit; 
  }

  /**
   * Gets the version number of the library.
   */
  static String getVersion() => "6.3.3";

  // -------------------------------------------------------------------------
  // Static -- pool
  // -------------------------------------------------------------------------

  static final Callback<Tween> _poolCallback = new Callback<Tween>()
      ..onPool = (Tween obj) { obj.reset(); }
      ..onUnPool = (Tween obj) { obj.reset(); };
      

  static final Pool<Tween> _pool = new Pool<Tween>(_poolCallback)
      ..create = () => new Tween._();
 

  /**
   * Used for debug purpose. Gets the current number of objects that are
   * waiting in the Tween pool.
   */
  int getPoolSize() => _pool.size();

  /**
   * Increases the minimum capacity of the pool. Capacity defaults to 20.
   */
  static void ensurePoolCapacity(int minCapacity) => _pool.ensureCapacity(minCapacity);

  // -------------------------------------------------------------------------
  // Static -- tween accessors
  // -------------------------------------------------------------------------

  static final Map<Type, TweenAccessor> _registeredAccessors = new Map<Type, TweenAccessor>();

  /**
   * Registers an accessor with the class of an object. This accessor will be
   * used by tweens applied to every objects implementing the registered
   * class, or inheriting from it.
   *
   * @param someClass An object class.
   * @param defaultAccessor The accessor that will be used to tween any
   * object of class "someClass".
   */
  static void registerAccessor(Type someClass, TweenAccessor defaultAccessor) {
    _registeredAccessors[someClass] = defaultAccessor;
  }

  /**
   * Gets the registered TweenAccessor associated with the given object class.
   *
   * @param someClass An object class.
   */
  static TweenAccessor getRegisteredAccessor(Type someClass) {
    return _registeredAccessors[someClass];
  }

  // -------------------------------------------------------------------------
  // Static -- factories
  // -------------------------------------------------------------------------

  /**
   * Factory creating a new standard interpolation. This is the most common
   * type of interpolation. The starting values are retrieved automatically
   * after the delay (if any).
   * <br/><br/>
   *
   * <b>You need to set the target values of the interpolation by using one
   * of the target() methods</b>. The interpolation will run from the
   * starting values to these target values.
   * <br/><br/>
   *
   * The common use of Tweens is "fire-and-forget": you do not need to care
   * for tweens once you added them to a TweenManager, they will be updated
   * automatically, and cleaned once finished. Common call:
   * <br/><br/>
   *
   * <pre> {@code
   * Tween.to(myObject, POSITION, 1.0f)
   *      .target(50, 70)
   *      .ease(Quad.INOUT)
   *      .start(myManager);
   * }</pre>
   *
   * Several options such as delay, repetitions and callbacks can be added to
   * the tween.
   *
   * @param target The target object of the interpolation.
   * @param tweenType The desired type of interpolation.
   * @param duration The duration of the interpolation, in milliseconds.
   * @return The generated Tween.
   */
  static Tween to(Object target, int tweenType, num duration) {
    Tween tween = _pool.get()
        ..easing = Quad.INOUT
        .._setup(target, tweenType, duration)
        ..path = TweenPaths.catmullRom;
    return tween;
  }

  /**
   * Factory creating a new reversed interpolation. The ending values are
   * retrieved automatically after the delay (if any).
   * <br/><br/>
   *
   * <b>You need to set the starting values of the interpolation by using one
   * of the target() methods</b>. The interpolation will run from the
   * starting values to these target values.
   * <br/><br/>
   *
   * The common use of Tweens is "fire-and-forget": you do not need to care
   * for tweens once you added them to a TweenManager, they will be updated
   * automatically, and cleaned once finished. Common call:
   * <br/><br/>
   *
   * <pre> {@code
   * Tween.from(myObject, POSITION, 1.0f)
   *      .target(0, 0)
   *      .ease(Quad.INOUT)
   *      .start(myManager);
   * }</pre>
   *
   * Several options such as delay, repetitions and callbacks can be added to
   * the tween.
   *
   * @param target The target object of the interpolation.
   * @param tweenType The desired type of interpolation.
   * @param duration The duration of the interpolation, in milliseconds.
   * @return The generated Tween.
   */
  static Tween from(Object target, int tweenType, num duration) {
    Tween tween = _pool.get()
      .._setup(target, tweenType, duration)
      ..easing = Quad.INOUT
      ..path = TweenPaths.catmullRom
      .._isFrom = true;
    return tween;
  }

  /**
   * Factory creating a new instantaneous interpolation (thus this is not
   * really an interpolation).
   * <br/><br/>
   *
   * <b>You need to set the target values of the interpolation by using one
   * of the target() methods</b>. The interpolation will set the target
   * attribute to these values after the delay (if any).
   * <br/><br/>
   *
   * The common use of Tweens is "fire-and-forget": you do not need to care
   * for tweens once you added them to a TweenManager, they will be updated
   * automatically, and cleaned once finished. Common call:
   * <br/><br/>
   *
   * <pre> {@code
   * Tween.set(myObject, POSITION)
   *      .target(50, 70)
   *      .delay(1.0f)
   *      .start(myManager);
   * }</pre>
   *
   * Several options such as delay, repetitions and callbacks can be added to
   * the tween.
   *
   * @param target The target object of the interpolation.
   * @param tweenType The desired type of interpolation.
   * @return The generated Tween.
   */
  static Tween set(Object target, int tweenType) {
    Tween tween = _pool.get()
        .._setup(target, tweenType, 0)
        ..easing = TweenEquations.easeInQuad;
    return tween;
  }

  /**
   * Factory creating a new timer. The given callback will be triggered on
   * each iteration start, after the delay.
   * <br/><br/>
   *
   * The common use of Tweens is "fire-and-forget": you do not need to care
   * for tweens once you added them to a TweenManager, they will be updated
   * automatically, and cleaned once finished. Common call:
   * <br/><br/>
   *
   * <pre> {@code
   * Tween.call(myCallback)
   *      .delay(1.0f)
   *      .repeat(10, 1000)
   *      .start(myManager);
   * }</pre>
   *
   * @param callback The callback that will be triggered on each iteration
   * start.
   * @return The generated Tween.
   * @see TweenCallback
   */
  static Tween callBack(TweenCallback callback) {
    Tween tween = _pool.get()
        .._setup(null, -1, 0)
        ..setCallback(callback)
        ..setCallbackTriggers(TweenCallback.START);
    return tween;
  }

  /**
   * Convenience method to create an empty tween. Such object is only useful
   * when placed inside animation sequences (see {@link Timeline}), in which
   * it may act as a beacon, so you can set a callback on it in order to
   * trigger some action at the right moment.
   *
   * @return The generated Tween.
   * @see Timeline
   */
  static Tween mark() {
    Tween tween = _pool.get()
        .._setup(null, -1, 0);    
    return tween;
  }

  // -------------------------------------------------------------------------
  // Attributes
  // -------------------------------------------------------------------------

  // Main
  Object _target;
  Type _targetClass;
  TweenAccessor<Object> _accessor;
  int _type;
  TweenEquation _equation;
  TweenPath _path;

  // General
  bool _isFrom;
  bool _isRelative;
  int _combinedAttrsCnt;
  int _waypointsCnt;

  // Values
  final List<num> _startValues = new List<num>(_combinedAttrsLimit);
  final List<num> _targetValues = new List<num>(_combinedAttrsLimit);
  final List<num> _waypoints = new List<num>(_waypointsLimit * _combinedAttrsLimit);

  // Buffers
  List<num> _accessorBuffer = new List<num>(_combinedAttrsLimit);
  List<num> _pathBuffer = new List<num>((2+ _waypointsLimit)*_combinedAttrsLimit);

  // -------------------------------------------------------------------------
  // Setup
  // -------------------------------------------------------------------------

  Tween._() {
    reset();
  }

  //@Override
  void reset() {
    super.reset();

    _target = null;
    _targetClass = null;
    _accessor = null;
    _type = -1;
    _equation = null;
    _path = null;

    _isFrom = _isRelative = false;
    _combinedAttrsCnt = _waypointsCnt = 0;

    if (_accessorBuffer.length != _combinedAttrsLimit) {
            _accessorBuffer = new Float32List(_combinedAttrsLimit);
    }

    if (_pathBuffer.length != (2+ _waypointsLimit) * _combinedAttrsLimit) {
            _pathBuffer = new Float32List((2+ _waypointsLimit) * _combinedAttrsLimit);
    }
  }

  void _setup(Object target, int tweenType, num duration) {
    if (duration < 0) throw new Exception("Duration can't be negative");

    _target = target;
    _targetClass = target != null ? _findTargetClass() : null;
    _type = tweenType;
    _duration = duration;
  }

  Type _findTargetClass() {
    if (_registeredAccessors.containsKey(_target.runtimeType)) return _target.runtimeType;
    if (_target is TweenAccessor) return _target.runtimeType;
          
    //TODO: find out about this
//                Type parentClass = _target.runtimeType.getSuperclass();
//                while (parentClass != null && !_registeredAccessors.containsKey(parentClass))
//                        parentClass = parentClass.getSuperclass();
//
//                return parentClass;
    return null;
  }

  // -------------------------------------------------------------------------
  // API
  // -------------------------------------------------------------------------

  
  /**
   * Forces the tween to use the TweenAccessor registered with the given target class. Useful if you want to use a specific accessor associated
   * to an interface, for instance.
   *
   * @param targetClass A class registered with an accessor.
   * @return The current tween, for chaining instructions.
   */
  void cast(Type targetClass) {
    if (isStarted) throw new Exception("You can't cast the target of a tween once it is started");
    _targetClass = targetClass;
  }
        
  /**
   * Sets the easing equation of the tween. Existing equations can be accessed via 
   * [TweenEquations] static instances, but you can of course implement your owns, see [TweenEquation]. 
   * Default equation is Quad.INOUT.
   *
   * Proposed equations are:
   * * Linear.INOUT,<br/>
   * * Quad.IN | OUT | INOUT,<br/>
   * * Cubic.IN | OUT | INOUT,<br/>
   * * Quart.IN | OUT | INOUT,<br/>
   * * Quint.IN | OUT | INOUT,<br/>
   * * Circ.IN | OUT | INOUT,<br/>
   * * Sine.IN | OUT | INOUT,<br/>
   * * Expo.IN | OUT | INOUT,<br/>
   * * Back.IN | OUT | INOUT,<br/>
   * * Bounce.IN | OUT | INOUT,<br/>
   * * Elastic.IN | OUT | INOUT
   *
   * @see TweenEquation
   * @see TweenEquations
   */
  void set easing(TweenEquation easeEquation) {
    _equation = easeEquation;
  }

  
  
  /**
   * Sets the target values of the interpolation. The interpolation will run from the 
   * **values at start time (after the delay, if any)** to these target values.
   *
   * To sum-up:
   * - start values: values at start time, after delay
   * - end values: params
   *
   * targetValues The target value(s)s of the interpolation. Can be either a num, or a List<num> if 
   * multiple target values are needed
   * @return The current tween, for chaining instructions.
   */
  void set targetValues(targetValues) {
    if(targetValues is num)
      _targetValues[0] = targetValues;
    else if (targetValues is List<num>){
      if (_targetValues.length > _combinedAttrsLimit) _throwCombinedAttrsLimitReached();
      _targetValues.setAll(0, targetValues);
    }
    //System.arraycopy(targetValues, 0, this._targetValues, 0, _targetValues.length);
  }

  /**
   * Sets the target values of the interpolation, relatively to the **values
   * at start time (after the delay, if any)**.
   *
   * To sum-up:<br/>
   * - start values: values at start time, after delay<br/>
   * - end values: params + values at start time, after delay
   *
   * targetValues The relative target values of the interpolation. Can be either a num, or a List<num> if 
   * multiple target values are needed
   * @return The current tween, for chaining instructions.
   */
  void set targetRelative(targetValues) {
    if(targetValues is num)
      _targetValues[0] = isInitialized ? targetValues + _startValues[0] : targetValues;
    else if (targetValues is List<num>){
      if (targetValues.length > _combinedAttrsLimit) _throwCombinedAttrsLimitReached();
      for (int i=0; i< targetValues.length; i++) {
        _targetValues[i] = isInitialized ? targetValues[i] + _startValues[i] : targetValues[i];
      }
    }

    _isRelative = true;
  }

  /**
   * Adds a waypoint to the path. The default path runs from the start values
   * to the end values linearly. If you add waypoints, the default path will
   * use a smooth catmull-rom spline to navigate between the waypoints, but
   * you can change this behavior by using the {@link #path(TweenPath)}
   * method.
   *
   * targetValues The targets of this waypoint. Can be either a num, or a List<num> 
   */
  void set waypoint(targetValues) {
    if(targetValues is num){
          if (_waypointsCnt == _waypointsLimit) _throwWaypointsLimitReached();
          _waypoints[_waypointsCnt] = targetValues;
          _waypointsCnt += 1;
    }else if (targetValues is List<num>){
      if (_waypointsCnt == _waypointsLimit) _throwWaypointsLimitReached();
      //System.arraycopy(targetValues, 0, waypoints, waypointsCnt*_targetValues.length, _targetValues.length);
      _waypointsCnt += 1;
    }
  }

//        /**
//         * Adds a waypoint to the path. The default path runs from the start values
//         * to the end values linearly. If you add waypoints, the default path will
//         * use a smooth catmull-rom spline to navigate between the waypoints, but
//         * you can change this behavior by using the {@link #path(TweenPath)}
//         * method.
//         * <p/>
//         * Note that if you want waypoints relative to the start values, use one of
//         * the .targetRelative() methods to define your target.
//         *
//         * @param targetValues The targets of this waypoint.
//         * @return The current tween, for chaining instructions.
//         */
//        void waypoint(float... targetValues) {
//          if (waypointsCnt == waypointsLimit) _throwWaypointsLimitReached();
//          System.arraycopy(targetValues, 0, waypoints, waypointsCnt*_targetValues.length, _targetValues.length);
//          waypointsCnt += 1;
//          return this;
//        }

  /**
   * Sets the algorithm that will be used to navigate through the waypoints,
   * from the start values to the end values. Default is a catmull-rom spline,
   * but you can find other paths in the {@link TweenPaths} class.
   *
   * @param path A TweenPath implementation.
   * @return The current tween, for chaining instructions.
   * @see TweenPath
   * @see TweenPaths
   */
  void set path(TweenPath path) {
    _path = path;
  }

  // -------------------------------------------------------------------------
  // Getters
  // -------------------------------------------------------------------------

  ///Gets the target object.
  get target => _target;

  ///Gets the type of the tween.
  //int tweenType => _type;

  ///Gets the easing equation.
  TweenEquation get easing => _equation;

  /**
   * Gets the target values. The returned buffer is as long as the maximum
   * allowed combined values. Therefore, you're surely not interested in all
   * its content. Use {@link #getCombinedTweenCount()} to get the number of
   * interesting slots.
   */
  List<num> get targetValues => _targetValues;

  ///Gets the number of combined animations.
  int get combinedAttributesCount=> _combinedAttrsCnt;

  ///Gets the TweenAccessor used with the target.
  TweenAccessor get accessor=> _accessor;

  ///Gets the class that was used to find the associated TweenAccessor.
  Type get targetClass => _targetClass;

  // -------------------------------------------------------------------------
  // Overrides
  // -------------------------------------------------------------------------

  void build() {
    if (_target == null) return ;

    _accessor = _registeredAccessors[_targetClass];
    if (_accessor == null && _target is TweenAccessor) _accessor = _target;
    if (_accessor != null) { 
      _combinedAttrsCnt = _accessor.getValues(_target, _type, _accessorBuffer) ;
      if (_combinedAttrsCnt == null)
        _combinedAttrsCnt = 0;
    }
    else throw new Exception("No TweenAccessor was found for the target");

    if (_combinedAttrsCnt > _combinedAttrsLimit) _throwCombinedAttrsLimitReached();
  }

  void free() {
    _pool.free(this);
  }

  void initializeOverride() {
    if (_target == null) return;

    _accessor.getValues(_target, _type, _startValues);

    for (int i=0; i<_combinedAttrsCnt; i++) {
      _targetValues[i] += _isRelative ? _startValues[i] : 0;

      for (int ii=0; ii<_waypointsCnt; ii++) {
        _waypoints[ii*_combinedAttrsCnt+i] += _isRelative ? _startValues[i] : 0;
      }

      if (_isFrom) {
        num tmp = _startValues[i];
        _startValues[i] = _targetValues[i];
        _targetValues[i] = tmp;
      }
    }
  }

  void updateOverride(int step, int lastStep, bool isIterationStep, num delta) {
    if (_target == null || _equation == null) return;

    // Case iteration end has been reached

    if (!isIterationStep && step > lastStep) {
      _accessor.setValues(_target, _type, isReverse(lastStep) ? _startValues : _targetValues);
      return;
    }

    if (!isIterationStep && step < lastStep) {
      _accessor.setValues(_target, _type, isReverse(lastStep) ? _targetValues : _startValues);
      return;
    }

    // Validation

    assert (isIterationStep);
    assert (currentTime >= 0);
    assert (currentTime <= duration);

    // Case duration equals zero

    if (duration < 0.00000000001 && delta > -0.00000000001) {
      _accessor.setValues(_target, _type, isReverse(step) ? _targetValues : _startValues);
      return;
    }

    if (duration < 0.00000000001 && delta < 0.00000000001) {
      _accessor.setValues(_target, _type, isReverse(step) ? _startValues : _targetValues);
      return;
    }

    // Normal behavior

    num time = isReverse(step) ? duration - currentTime : currentTime;
    num t = _equation.compute(time/duration);

    if (_waypointsCnt == 0 || _path == null) {
      for (int i=0; i<_combinedAttrsCnt; i++) {
        _accessorBuffer[i] = _startValues[i] + t * (_targetValues[i] - _startValues[i]);
      }

    } else {
      for (int i=0; i<_combinedAttrsCnt; i++) {
        _pathBuffer[0] = _startValues[i];
        _pathBuffer[1+_waypointsCnt] = _targetValues[i];
        for (int ii=0; ii<_waypointsCnt; ii++) {
          _pathBuffer[ii+1] = _waypoints[ii*_combinedAttrsCnt+i];
        }

        _accessorBuffer[i] = _path.compute(t, _pathBuffer, _waypointsCnt + 2);
      }
    }

    _accessor.setValues(_target, _type, _accessorBuffer);
  }

  // -------------------------------------------------------------------------
  // BaseTween impl.
  // -------------------------------------------------------------------------

  void forceStartValues() {
    if (_target == null) return;
    _accessor.setValues(_target, _type, _startValues);
  }

  void forceEndValues() {
    if (_target == null) return;
    _accessor.setValues(_target, _type, _targetValues);
  }

  bool containsTarget(Object target, [int tweenType = null]) {
    if (tweenType = null)
      return _target == target;
    return _target == target && _type == tweenType;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  void _throwCombinedAttrsLimitReached() {
          String msg = """You cannot combine more than $_combinedAttrsLimit 
                  attributes in a tween. You can raise this limit with 
                  Tween.setCombinedAttributesLimit(), which should be called once
                  in application initialization code.""";
          throw new Exception(msg);
  }

  void _throwWaypointsLimitReached() {
          String msg = """You cannot add more than $_waypointsLimit 
                  waypoints to a tween. You can raise this limit with
                  Tween.setWaypointsLimit(), which should be called once in
                  application initialization code.""";
          throw new Exception(msg);
  }
}