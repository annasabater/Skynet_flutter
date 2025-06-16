// lib/screens/drone_control_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../services/socket_service.dart';

class DroneControlPage extends StatefulWidget {
  final String sessionId;
  const DroneControlPage({super.key, required this.sessionId});

  @override
  State<DroneControlPage> createState() => _DroneControlPageState();
}

class _DroneControlPageState extends State<DroneControlPage> {
  IO.Socket? _socket;
  final MapController _mapController = MapController();

  bool   _showMap      = true;
  bool   _mapLocked    = false;
  bool   _gameFinished = false;
  double _currentZoom  = 20;

  final Map<String, Marker>  _droneMarkers  = {};
  final Map<String, Marker>  _bulletMarkers = {};
  final Map<String, Polygon> _fencePolygons = {};
  final Map<String, Polygon> _obstaclePolys = {};
  final Map<String, int>     _scores        = {};
  final Map<String, String> _droneStates   = {};
  final Map<String, Map<String, dynamic>> _telemetry = {};
  final Map<String, double> _headings      = {};

  bool   _blinkVisible = true;
  Timer? _blinkTimer;

  int _bulletUid = 0;
  Map<String, dynamic>? _myTelemetry;

  Timer?              _throttleTimer;
  static const double _deadZone       = 0.7;
  static const double _maxSpeed       = 0.3;
  static const Duration _throttlePeriod = Duration(milliseconds: 100);

  static const Map<String, Color> _playerColor = {
    'dron_rojo1@upc.edu'    : Colors.red,
    'dron_azul1@upc.edu'    : Colors.blue,
    'dron_verde1@upc.edu'   : Colors.green,
    'dron_amarillo1@upc.edu': Colors.amber,
  };
  bool _isCompetitor(String email) => _playerColor.containsKey(email);

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

void _connectSocket() {
  final token = SocketService.jwt;
  _socket = IO.io(
    '${SocketService.baseUrl}/jocs',
    {
      'transports' : ['websocket'],
      'auth'       : {'token': token},
      'autoConnect': false,
    },
  )..connect();

  _socket!
  ..on('connect', (_) {
    _socket!.emit('join', {'sessionId': widget.sessionId});
  })

  ..on('game_started', (_) {
    if (!mounted) return;
    _resetScenarioContents();
    setState(() {
      _gameFinished = false;
      _showMap      = true;
      _mapLocked    = false;
    });
  })

  ..on('game_ended', (_) {
    if (!mounted || _gameFinished) return;
    _resetScenarioContents();    
    setState(() {
      _gameFinished = true;
      _showMap      = true;
      _mapLocked    = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/');
    });
  })

    ..on('state_update', _handleStateUpdate)
    ..on('score_update', (data) {
      final drone = data['drone'] as String;
      final pts   = (data['payload']['score'] as num).toInt();
      _scores[drone] = pts;
      setState(() {});
    })
    ..on('bullet_create',  (d) => _updateBullet(d['payload'], create: true))
    ..on('bullet_move',    (d) => _updateBullet(d['payload'], create: false))
    ..on('bullet_destroy', (d) {
      _bulletMarkers.remove(d['payload']['bulletId']);
      setState(() {});
    })
    ..on('fence_add', (d) {
      _addFence(d['payload']['geometry'], d['drone']);
      setState(() {});
    })
    ..on('fence_remove', (_) {
      _fencePolygons.clear();
      setState(() {});
    })
    ..on('obstacle_add', (d) {
      _addObstacle(d['payload']['geometry'] as List);
      setState(() {});
    })
    ..on('obstacle_remove', (d) {
      _removeObstacle(d['payload']['geometry'] as List);
      setState(() {});
    });
}

  void _handleStateUpdate(dynamic data) {
    if (_gameFinished) return;

    final action  = data['action'] ?? '';
    final drone   = data['drone']  ?? '';
    final payload = data['payload'] as Map<String, dynamic>? ?? {};

    switch (action) {
      case 'telemetry':
        _updateDrone(drone, payload);
        break;
      case 'state':
        final newState = payload['state'] as String? ?? 'flying';
        _droneStates[drone] = newState;
        _rebuildMarker(drone);
        _syncBlinkTimer();
        setState(() {});
        break;
      case 'score_update':
        _scores[drone] = (payload['score'] as num).toInt();
        setState(() {});
        break;
      case 'bullet_create':
      case 'bullet_move':
        _updateBullet(payload, create: action == 'bullet_create');
        break;
      case 'bullet_destroy':
        _bulletMarkers.remove(payload['bulletId']);
        setState(() {});
        break;
      case 'fence_add':
        _addFence(payload['geometry'], drone);
        setState(() {});
        break;
      case 'fence_remove':
        _fencePolygons.clear();
        setState(() {});
        break;
      case 'obstacle_add':
        _addObstacle(payload['geometry'] as List);
        setState(() {});
        break;
      case 'obstacle_remove':
        _removeObstacle(payload['geometry'] as List);
        setState(() {});
        break;
    }
  }

  void _syncBlinkTimer() {
    final anyLanded = _droneStates.values.any((s) => s == 'landed');
    if (anyLanded && (_blinkTimer == null || !_blinkTimer!.isActive)) {
      _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        _blinkVisible = !_blinkVisible;
        for (final email in _droneStates.keys) {
          if (_droneStates[email] == 'landed') _rebuildMarker(email);
        }
        setState(() {});
      });
    } else if (!anyLanded) {
      _blinkTimer?.cancel();
      _blinkTimer = null;
      _blinkVisible = true;
    }
  }

  void _resetScenario() {
    _droneMarkers.clear();
    _bulletMarkers.clear();
    _fencePolygons.clear();
    _obstaclePolys.clear();
    _scores.clear();
    _droneStates.clear();
    _telemetry.clear();
    _headings.clear();
    _bulletUid      = 0;
    _myTelemetry    = null;
    _currentZoom    = 20;
    _mapLocked      = true;
    _blinkTimer?.cancel();
    _blinkTimer     = null;
    _blinkVisible   = true;
    setState(() {});
  }

  void _resetScenarioContents() {
    _droneMarkers.clear();
    _bulletMarkers.clear();
    _fencePolygons.clear();
    _obstaclePolys.clear();
    _scores.clear();
    _droneStates.clear();
    _telemetry.clear();
    _headings.clear();
    _bulletUid = 0;
    _myTelemetry = null;
    _currentZoom = 20;
    _mapLocked = true;
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _blinkVisible = true;
  }


  void _updateDrone(String email, Map<String, dynamic> p) {
    if (!_isCompetitor(email)) return;

    _telemetry[email] = p;
    final hdg = (p['heading'] as num?)?.toDouble() ?? 0;
    _headings[email] = hdg;

    if (email == SocketService.currentUserEmail) _myTelemetry = p;

    _rebuildMarker(email);
    setState(() {});
  }

  void _rebuildMarker(String email) {
    final p = _telemetry[email];
    if (p == null) return;

    final lat   = p['lat'] as double;
    final lon   = p['lon'] as double;
    final hdg   = _headings[email] ?? 0;
    final color = _playerColor[email] ?? Colors.grey;
    final state = _droneStates[email] ?? 'active';

    final double opacity = state == 'landed' ? (_blinkVisible ? 1.0 : 0.0) : 1.0;

    _droneMarkers[email] = Marker(
      point : LatLng(lat, lon),
      width : 34,
      height: 34,
      child : Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: hdg * pi / 180,
          child: Icon(Icons.airplanemode_active, color: color, size: 34),
        ),
      ),
    );
  }

  void _updateBullet(Map<String, dynamic> p, {required bool create}) {
    final id  = p['bulletId'] as String;
    final lat = p['lat'] as double;
    final lon = p['lon'] as double;

    _bulletMarkers[id] = Marker(
      point : LatLng(lat, lon),
      width : 12,
      height: 12,
      child : const Icon(Icons.fiber_manual_record, size: 12, color: Colors.black),
    );
    if (!create) setState(() {});
  }

  void _addFence(dynamic geometry, String droneEmail) {
    if (geometry is! List || !_isCompetitor(droneEmail)) return;
    final points = geometry
        .map<LatLng>((pt) => LatLng(pt['lat'] as double, pt['lon'] as double))
        .toList();
    final color = _playerColor[droneEmail] ?? Colors.grey;

    _fencePolygons[droneEmail] = Polygon(
      points          : points,
      color           : color.withOpacity(0.25),
      borderColor     : color,
      borderStrokeWidth: 3,
    );
  }

  String _obstacleKey(List geom) => geom.map((e) => '${e['lat']},${e['lon']}').join('|');

  void _addObstacle(List<dynamic> geometry) {
    final key    = _obstacleKey(geometry);
    final points = geometry
        .map<LatLng>((pt) => LatLng(pt['lat'] as double, pt['lon'] as double))
        .toList();

    _obstaclePolys[key] = Polygon(
      points          : points,
      color           : Colors.black.withOpacity(0.8),
      borderColor     : Colors.black,
      borderStrokeWidth: 1,
    );
  }

  void _removeObstacle(List<dynamic> geometry) {
    final key = _obstacleKey(geometry);
    _obstaclePolys.remove(key);
  }

  void _emitControl(String action, Map<String, dynamic> payload) {
    _socket!.emit('control', {
      'sessionId': widget.sessionId,
      'drone'    : SocketService.currentUserEmail,
      'action'   : action,
      'payload'  : payload,
    });
  }

  void _onJoy(String stick, Offset off) {
    if (_gameFinished) return;

    final mag = sqrt(off.dx * off.dx + off.dy * off.dy);
    if (mag < _deadZone) {
      if (stick == 'right') {
        _emitControl('move', {'dx': 0.0, 'dy': 0.0});
      } else {
        _emitControl('throttle', {'dz': 0.0});
        _emitControl('yaw',      {'dyaw': 0.0});
      }
      return;
    }

    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(_throttlePeriod, () {});

    final nx = off.dx / mag;
    final ny = off.dy / mag;
    final f  = ((mag - _deadZone) / (1 - _deadZone))
        .clamp(0.0, 1.0) * _maxSpeed;

    if (stick == 'right') {
      _emitControl('move',   {'dx': nx * f, 'dy': -ny * f});
    } else {
      _emitControl('throttle', {'dz': -ny * f});
      _emitControl('yaw',      {'dyaw': nx * f});
    }
  }

  void _fire(String type) {
    if (_gameFinished) return;
    final id = 'b\${_bulletUid++}';
    _socket!.emit('control', {
      'sessionId': widget.sessionId,
      'drone'    : SocketService.currentUserEmail,
      'action'   : 'fire',
      'payload'  : {'type': type, 'bulletId': id},
    });
  }

  Widget _buildMap() => FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: LatLng(41.2764478, 1.9886568),
          zoom: _currentZoom,
          interactiveFlags:
              _mapLocked ? InteractiveFlag.none : InteractiveFlag.all,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            subdomains: const ['server'],
            userAgentPackageName: 'com.example.seminari_flutter',
          ),
          if (_fencePolygons.isNotEmpty)
            PolygonLayer(polygons: _fencePolygons.values.toList()),
          if (_obstaclePolys.isNotEmpty)
            PolygonLayer(polygons: _obstaclePolys.values.toList()),
          MarkerLayer(markers: [
            ..._droneMarkers.values,
            ..._bulletMarkers.values
          ]),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final telemetryLabel = _myTelemetry == null
        ? const SizedBox.shrink()
        : Positioned(
            top: 56,
            left: 16,
            child: Text(
              'Pos: ${(_myTelemetry!['lat'] as double).toStringAsFixed(5)}, '
              '${(_myTelemetry!['lon'] as double).toStringAsFixed(5)}   '
              'Hd: ${(_myTelemetry!['heading'] as num).toStringAsFixed(1)}°',
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          );

    final scoreLabel = _scores.isEmpty
        ? const SizedBox.shrink()
        : Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _scores.entries.map((e) {
                  final clr  = _playerColor[e.key]!;
                  final name = {
                    'dron_rojo1@upc.edu'    : 'Jugador 1 (Rojo)',
                    'dron_azul1@upc.edu'    : 'Jugador 2 (Azul)',
                    'dron_verde1@upc.edu'   : 'Jugador 3 (Verde)',
                    'dron_amarillo1@upc.edu': 'Jugador 4 (Amarillo)',
                  }[e.key] ?? e.key.split('@').first;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '$name: ${e.value}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: clr),
                    ),
                  );
                }).toList(),
              ),
            ),
          );

    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F5),
      body: SafeArea(
        child: Stack(
          children: [
            if (_showMap) Positioned.fill(child: _buildMap()),

            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: Icon(_showMap ? Icons.layers_clear : Icons.layers),
                onPressed: () => setState(() => _showMap = !_showMap),
              ),
            ),

            // Zoom +/− y lock
            if (_showMap) ...[
              _zoomBtn( 70, Icons.add, () {
                setState(() {
                  _currentZoom++;
                  _mapController.move(_mapController.center, _currentZoom);
                });
              }),
              _zoomBtn(130, Icons.remove, () {
                setState(() {
                  _currentZoom--;
                  _mapController.move(_mapController.center, _currentZoom);
                });
              }),
              _zoomBtn(190, _mapLocked ? Icons.lock : Icons.lock_open,
                  () => setState(() => _mapLocked = !_mapLocked)),
            ],

            telemetryLabel,
            scoreLabel,

            Positioned(
              top: 30,
              right: 16,
              child: Column(
                children: [
                  _bulletBtn('assets/bullet1.png', 'small_fast'),
                  const SizedBox(height: 12),
                  _bulletBtn('assets/bullet2.png', 'medium'),
                  const SizedBox(height: 12),
                  _bulletBtn('assets/bullet3.png', 'large_slow'),
                ],
              ),
            ),

            if (!_gameFinished)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_joystick('left'), _joystick('right')],
                  ),
                ),
              ),

            if (_gameFinished) _buildGameOverOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context) => Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PARTIDA FINALIZADA',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Ir al Home'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ),
      );

  Widget _zoomBtn(double top, IconData icon, VoidCallback cb) => Positioned(
    top: top,
    left: 16,
    child: GestureDetector(
      onTap: cb,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Icon(icon, size: 24, color: Colors.black87),
      ),
    ),
  );

  Widget _joystick(String id) => Joystick(
        listener: (d) => _onJoy(id, Offset(d.x, d.y)),
        mode: JoystickMode.all,
        base: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
                color: Color(0xFF2F3B4C), shape: BoxShape.circle)),
        stick: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7), shape: BoxShape.circle)),
      );

  Widget _bulletBtn(String asset, String type) => GestureDetector(
      onTap: () => _fire(type),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE0E0E0), Color(0xFFFAFAFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
      ),
    );


  @override
  void dispose() {
    _socket
      ?..offAny()          
      ..disconnect()
      ..destroy();
    _throttleTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }
}