import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import '../models/run_data.dart';
import '../models/chaser.dart';
import '../models/power_up.dart';

class RunProvider with ChangeNotifier {
  // Run state
  bool _isRunning = false;
  bool _isPaused = false;
  DateTime? _startTime;
  List<Position> _positions = [];
  List<RunData> _pastRuns = [];
  RunData? _currentRun;
  RunData? _ghostRun;
  List<LatLng> _route = [];

  // Chase mechanics
  Chaser _chaser = Chaser.defaultChaser();
  double _chaserDistance = 100.0; // meters behind
  List<PowerUp> _availablePowerUps = [];
  final List<PowerUp> _activePowerUps = [];

  // Metrics
  double _distance = 0.0;
  double _elevation = 0.0;
  double _calories = 0.0;
  double _currentSpeed = 0.0;
  double _averageSpeed = 0.0;
  Duration _duration = Duration.zero;

  // Streaming controllers
  Stream<Position> positionStream =
      Geolocator.getPositionStream().asBroadcastStream();
  final StreamController<Position> _locationController =
      StreamController.broadcast();
  StreamSubscription<Position>? _positionStreamSubscription;

  // Text to speech
  final FlutterTts _flutterTts = FlutterTts();

  // Getters
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  double get distance => _distance;
  double get elevation => _elevation;
  double get calories => _calories;
  double get currentSpeed => _currentSpeed;
  double get averageSpeed => _averageSpeed;
  Duration get duration => _duration;
  Chaser get chaser => _chaser;
  double get chaserDistance => _chaserDistance;
  List<PowerUp> get availablePowerUps => _availablePowerUps;
  List<PowerUp> get activePowerUps => _activePowerUps;
  List<RunData> get pastRuns => _pastRuns;
  RunData? get currentRun => _currentRun;
  RunData? get ghostRun => _ghostRun;
  List<LatLng> get route => _route;

  // Change the return type to Stream<Position>
  Stream<Position> get locationStream => _locationController.stream;

  // Initialize
  RunProvider() {
    _initTts();
    _loadPastRuns();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _loadPastRuns() {
    // In a real app, load from local storage or cloud
    // For now, we'll use dummy data
    _pastRuns = [
      RunData(
        id: '1',
        date: DateTime.now().subtract(const Duration(days: 2)),
        distance: 5.2,
        duration: const Duration(minutes: 28, seconds: 45),
        calories: 320,
        avgSpeed: 11.2,
        elevationGain: 45,
        route: [],
      ),
      RunData(
        id: '2',
        date: DateTime.now().subtract(const Duration(days: 5)),
        distance: 3.8,
        duration: const Duration(minutes: 22, seconds: 15),
        calories: 240,
        avgSpeed: 10.5,
        elevationGain: 30,
        route: [],
      ),
    ];
  }

  // Run control methods
  Future<void> startRun({Chaser? customChaser, RunData? ghostRunData}) async {
    if (_isRunning) return;

    // Request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        speak("Location permission denied. Cannot start run.");
        return;
      }
    }

    // Set up run
    _isRunning = true;
    _isPaused = false;
    _startTime = DateTime.now();
    _positions = [];
    _distance = 0.0;
    _elevation = 0.0;
    _calories = 0.0;
    _currentSpeed = 0.0;
    _averageSpeed = 0.0;
    _duration = Duration.zero;
    _route = [];

    // Set up chaser
    if (customChaser != null) {
      _chaser = customChaser;
    } else {
      _chaser = Chaser.defaultChaser();
    }
    _chaserDistance = 100.0; // Start 100m behind

    // Set up ghost run
    _ghostRun = ghostRunData;

    // Set up power-ups
    _generatePowerUps();

    // Start location tracking
    _startLocationTracking();

    // Create current run object
    _currentRun = RunData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _startTime!,
      distance: 0,
      duration: Duration.zero,
      calories: 0,
      avgSpeed: 0,
      elevationGain: 0,
      route: [],
    );

    // Initial coach feedback
    speak("Run started. Good luck!");

    // Start timer for periodic updates
    Timer.periodic(const Duration(seconds: 1), _updateRunMetrics);

    notifyListeners();
  }

  void pauseRun() {
    if (!_isRunning || _isPaused) return;

    _isPaused = true;
    _positionStreamSubscription?.pause();
    speak("Run paused");
    notifyListeners();
  }

  void resumeRun() {
    if (!_isRunning || !_isPaused) return;

    _isPaused = false;
    _positionStreamSubscription?.resume();
    speak("Run resumed");
    notifyListeners();
  }

  void stopRun() {
    if (!_isRunning) return;

    _isRunning = false;
    _isPaused = false;
    _positionStreamSubscription?.cancel();

    // Finalize current run data
    if (_currentRun != null) {
      _currentRun!.distance = _distance;
      _currentRun!.duration = _duration;
      _currentRun!.calories = _calories;
      _currentRun!.avgSpeed = _averageSpeed;
      _currentRun!.elevationGain = _elevation;
      _currentRun!.route = List.from(_positions);

      // Save to past runs
      _pastRuns.add(_currentRun!);
      // In a real app, save to storage here
    }

    speak("Run completed. Great job!");
    notifyListeners();
  }

  void addRoutePoint(LatLng point) {
    _route.add(point);
    notifyListeners();
  }

  // Location tracking
  void _startLocationTracking() async {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (_isPaused) return;

      _positions.add(position);
      _locationController.add(position);

      // Update metrics based on new position
      _updateMetricsWithNewPosition(position);

      // Update chaser position
      _updateChaserPosition();

      // Check for power-ups
      _checkForPowerUps(position);

      notifyListeners();
    });
  }

  void _updateMetricsWithNewPosition(Position position) {
    if (_positions.length < 2) return;

    // Calculate distance increment
    final Position prevPosition = _positions[_positions.length - 2];
    final double distanceIncrement = Geolocator.distanceBetween(
      prevPosition.latitude,
      prevPosition.longitude,
      position.latitude,
      position.longitude,
    );

    // Update total distance
    _distance += distanceIncrement / 1000; // Convert to km

    // Update elevation
    if (position.altitude > 0 && prevPosition.altitude > 0) {
      final double elevationChange = position.altitude - prevPosition.altitude;
      if (elevationChange > 0) {
        _elevation += elevationChange;
      }
    }

    // Update current speed (km/h)
    if (position.speed > 0) {
      _currentSpeed = position.speed * 3.6; // Convert m/s to km/h
    }

    // Update average speed
    _averageSpeed = _distance / (_duration.inSeconds / 3600);

    // Update calories (simple estimation)
    // Assuming 60 calories burned per km for a 70kg person
    _calories = _distance * 60;
  }

  void _updateRunMetrics(Timer timer) {
    if (!_isRunning || _isPaused) {
      timer.cancel();
      return;
    }

    // Update duration
    final now = DateTime.now();
    _duration = now.difference(_startTime!);

    // Update current run
    if (_currentRun != null) {
      _currentRun!.duration = _duration;
      _currentRun!.distance = _distance;
      _currentRun!.calories = _calories;
      _currentRun!.avgSpeed = _averageSpeed;
      _currentRun!.elevationGain = _elevation;
    }

    // Process active power-ups
    _processActivePowerUps();

    notifyListeners();
  }

  // Chase mechanics
  void _updateChaserPosition() {
    if (_positions.isEmpty) return;

    // Calculate chaser speed based on difficulty and user's average speed
    double chaserSpeedFactor = 1.0;

    switch (_chaser.difficulty) {
      case ChaserDifficulty.easy:
        chaserSpeedFactor = 0.9; // 90% of user's speed
        break;
      case ChaserDifficulty.medium:
        chaserSpeedFactor = 1.0; // Same as user's speed
        break;
      case ChaserDifficulty.hard:
        chaserSpeedFactor = 1.1; // 110% of user's speed
        break;
      case ChaserDifficulty.extreme:
        chaserSpeedFactor = 1.2; // 120% of user's speed
        break;
    }

    // Apply power-up effects to chaser speed
    for (var powerUp in _activePowerUps) {
      if (powerUp.type == PowerUpType.slowChaser) {
        chaserSpeedFactor *= 0.7; // Slow chaser by 30%
      }
    }

    // Calculate how much the chaser should move
    double chaserSpeed = _averageSpeed * chaserSpeedFactor;

    // Convert to meters per second
    double chaserMeterPerSecond = chaserSpeed / 3.6;

    // Assume this is called roughly every second (or adjust accordingly)
    _chaserDistance -= chaserMeterPerSecond;

    // Ensure chaser distance doesn't go below 0
    _chaserDistance = max(0, _chaserDistance);

    // Provide audio feedback based on chaser distance
    _provideChaserFeedback();
  }

  void _provideChaserFeedback() {
    // Provide different feedback based on chaser distance
    if (_chaserDistance <= 10 && _chaserDistance > 0) {
      speak("${_chaser.name} is right behind you! Sprint!");
    } else if (_chaserDistance <= 30 && _chaserDistance > 10) {
      speak("${_chaser.name} is closing in! Pick up the pace!");
    } else if (_chaserDistance <= 50 && _chaserDistance > 30) {
      speak("${_chaser.name} is gaining on you!");
    } else if (_chaserDistance == 0) {
      speak("${_chaser.name} caught you! Try to break free!");
      // Implement "break free" mechanic here if desired
    }
  }

  // Power-up mechanics
  void _generatePowerUps() {
    _availablePowerUps = [];

    // Generate random power-ups along the expected route
    // In a real app, this would be more sophisticated
    final random = Random();

    // Add 3-5 random power-ups
    final numPowerUps = random.nextInt(3) + 3;

    for (int i = 0; i < numPowerUps; i++) {
      final powerUpType =
          PowerUpType.values[random.nextInt(PowerUpType.values.length)];

      // Power-up will appear after running a random distance
      final appearDistance = random.nextDouble() * (_distance + 2.0);

      _availablePowerUps.add(
        PowerUp(
          id: 'powerup_$i',
          type: powerUpType,
          duration: const Duration(seconds: 30),
          appearDistance: appearDistance,
          isCollected: false,
        ),
      );
    }
  }

  void _checkForPowerUps(Position position) {
    if (_availablePowerUps.isEmpty) return;

    // Check if any power-ups should be collected based on distance
    for (var powerUp in _availablePowerUps) {
      if (!powerUp.isCollected && _distance >= powerUp.appearDistance) {
        // In a real app, we'd check proximity to the actual power-up location
        // For this demo, we'll just collect it when we reach the right distance

        powerUp.isCollected = true;
        _activatePowerUp(powerUp);

        // Remove from available power-ups
        _availablePowerUps.removeWhere((p) => p.id == powerUp.id);

        break; // Only collect one power-up at a time
      }
    }
  }

  void _activatePowerUp(PowerUp powerUp) {
    // Clone the power-up and set activation time
    final activePowerUp = PowerUp(
      id: powerUp.id,
      type: powerUp.type,
      duration: powerUp.duration,
      appearDistance: powerUp.appearDistance,
      isCollected: true,
      activatedAt: DateTime.now(),
    );

    _activePowerUps.add(activePowerUp);

    // Provide feedback based on power-up type
    switch (powerUp.type) {
      case PowerUpType.speedBoost:
        speak("Speed boost activated!");
        // Speed boost would affect user's avatar in the UI
        break;
      case PowerUpType.slowChaser:
        speak("${_chaser.name} slowed down!");
        break;
      case PowerUpType.shield:
        speak("Shield activated! ${_chaser.name} can't catch you temporarily!");
        break;
      case PowerUpType.teleport:
        // Increase distance from chaser
        _chaserDistance += 50;
        speak("Teleport! You gained distance from ${_chaser.name}!");
        break;
    }

    notifyListeners();
  }

  void _processActivePowerUps() {
    final now = DateTime.now();
    final expiredPowerUps = <PowerUp>[];

    for (var powerUp in _activePowerUps) {
      if (powerUp.activatedAt != null) {
        final elapsedDuration = now.difference(powerUp.activatedAt!);

        if (elapsedDuration >= powerUp.duration) {
          expiredPowerUps.add(powerUp);

          // Provide feedback that power-up expired
          switch (powerUp.type) {
            case PowerUpType.speedBoost:
              speak("Speed boost expired.");
              break;
            case PowerUpType.slowChaser:
              speak("${_chaser.name} is back to normal speed!");
              break;
            case PowerUpType.shield:
              speak("Shield expired. ${_chaser.name} can catch you again!");
              break;
            case PowerUpType.teleport:
              // No expiration effect for teleport
              break;
          }
        }
      }
    }

    // Remove expired power-ups
    _activePowerUps.removeWhere((p) => expiredPowerUps.contains(p));
  }

  // Audio feedback
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  // Cleanup
  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _locationController.close();
    _flutterTts.stop();
    super.dispose();
  }
}
