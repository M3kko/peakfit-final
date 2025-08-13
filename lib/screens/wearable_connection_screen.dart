import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'preworkout_screen.dart';

class WearableConnectionScreen extends StatefulWidget {
  final String workoutType;
  final int duration;
  final List<String> soreMuscles;

  const WearableConnectionScreen({
    Key? key,
    required this.workoutType,
    required this.duration,
    required this.soreMuscles,
  }) : super(key: key);

  @override
  State<WearableConnectionScreen> createState() => _WearableConnectionScreenState();
}

class _WearableConnectionScreenState extends State<WearableConnectionScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _whoopSyncController;
  late AnimationController _ouraSyncController;
  late AnimationController _ringRotationController;
  late AnimationController _successCheckController;

  // Animations
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _pulse;
  late Animation<double> _glow;
  late Animation<double> _whoopSync;
  late Animation<double> _ouraSync;
  late Animation<double> _ringRotation;
  late Animation<double> _successCheck;

  // State
  bool _whoopConnecting = false;
  bool _whoopConnected = false;
  bool _ouraConnecting = false;
  bool _ouraConnected = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _whoopSyncController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _ouraSyncController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _ringRotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _successCheckController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _slideUp = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    _pulse = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glow = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _whoopSync = CurvedAnimation(
      parent: _whoopSyncController,
      curve: Curves.easeOutBack,
    );

    _ouraSync = CurvedAnimation(
      parent: _ouraSyncController,
      curve: Curves.easeOutBack,
    );

    _ringRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _ringRotationController,
      curve: Curves.linear,
    ));

    _successCheck = CurvedAnimation(
      parent: _successCheckController,
      curve: Curves.elasticOut,
    );
  }

  void _startAnimations() {
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _whoopSyncController.dispose();
    _ouraSyncController.dispose();
    _ringRotationController.dispose();
    _successCheckController.dispose();
    super.dispose();
  }

  void _connectWhoop() async {
    if (_whoopConnecting || _whoopConnected) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _whoopConnecting = true;
    });

    _ringRotationController.repeat();

    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 2));

    _ringRotationController.stop();
    _whoopSyncController.forward();
    _successCheckController.forward();

    setState(() {
      _whoopConnecting = false;
      _whoopConnected = true;
    });

    HapticFeedback.heavyImpact();
  }

  void _connectOura() async {
    if (_ouraConnecting || _ouraConnected) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _ouraConnecting = true;
    });

    _ringRotationController.repeat();

    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 2));

    _ringRotationController.stop();
    _ouraSyncController.forward();
    _successCheckController.forward();

    setState(() {
      _ouraConnecting = false;
      _ouraConnected = true;
    });

    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeIn,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideUp.value),
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                _buildTitleSection(),
                                const SizedBox(height: 40),
                                _buildWearableCards(),
                                const SizedBox(height: 30),
                                _buildDataInsights(),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A0A),
            const Color(0xFF0F0F0F),
            const Color(0xFF050505),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
            padding: EdgeInsets.zero,
          ),
          const Spacer(),
          Text(
            'SYNC WEARABLES',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Connect Your Devices',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w200,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sync your wearables for personalized workout recommendations',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildWearableCards() {
    return Column(
      children: [
        _buildWearableCard(
          'WHOOP',
          'Recovery & strain tracking',
          _whoopConnecting,
          _whoopConnected,
          _connectWhoop,
          _whoopSync,
          const Color(0xFF00B4D8),
        ),
        const SizedBox(height: 16),
        _buildWearableCard(
          'OURA',
          'Sleep & readiness insights',
          _ouraConnecting,
          _ouraConnected,
          _connectOura,
          _ouraSync,
          const Color(0xFFB388FF),
        ),
      ],
    );
  }

  Widget _buildWearableCard(
      String name,
      String description,
      bool isConnecting,
      bool isConnected,
      VoidCallback onConnect,
      Animation<double> syncAnimation,
      Color accentColor,
      ) {
    return GestureDetector(
      onTap: isConnected ? null : onConnect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isConnected
                ? [
              accentColor.withOpacity(0.1),
              accentColor.withOpacity(0.05),
            ]
                : [
              Colors.white.withOpacity(0.03),
              Colors.white.withOpacity(0.01),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isConnected
                ? accentColor.withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon/Logo area
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isConnected
                    ? accentColor.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isConnected
                      ? accentColor.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Center(
                child: isConnecting
                    ? AnimatedBuilder(
                  animation: _ringRotation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _ringRotation.value,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor.withOpacity(0.8),
                          ),
                        ),
                      ),
                    );
                  },
                )
                    : isConnected
                    ? ScaleTransition(
                  scale: _successCheck,
                  child: Icon(
                    Icons.check_circle,
                    color: accentColor,
                    size: 28,
                  ),
                )
                    : Icon(
                  Icons.watch,
                  color: Colors.white.withOpacity(0.6),
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isConnected ? accentColor : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected ? 'Connected' : description,
                    style: TextStyle(
                      color: isConnected
                          ? accentColor.withOpacity(0.8)
                          : Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Status/Action
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isConnected
                  ? Container(
                key: const ValueKey('connected'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SYNCED',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
                  : Container(
                key: const ValueKey('connect'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  'CONNECT',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataInsights() {
    final hasConnections = _whoopConnected || _ouraConnected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasConnections
              ? const Color(0xFFD4AF37).withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: hasConnections
                    ? const Color(0xFFD4AF37).withOpacity(0.8)
                    : Colors.white.withOpacity(0.4),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'DATA INSIGHTS',
                style: TextStyle(
                  color: hasConnections
                      ? const Color(0xFFD4AF37).withOpacity(0.8)
                      : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasConnections) ...[
            if (_whoopConnected) _buildInsightRow('Recovery Score', '85%', Colors.green),
            if (_whoopConnected) const SizedBox(height: 12),
            if (_ouraConnected) _buildInsightRow('Sleep Quality', '92%', Colors.blue),
            if (_ouraConnected) const SizedBox(height: 12),
            if (_whoopConnected || _ouraConnected)
              _buildInsightRow('Readiness', 'Optimal', const Color(0xFFD4AF37)),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.sync_disabled,
                      color: Colors.white.withOpacity(0.2),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect devices to see insights',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final canContinue = _whoopConnected || _ouraConnected;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFF0A0A0A),
              const Color(0xFF0A0A0A).withOpacity(0.9),
              const Color(0xFF0A0A0A).withOpacity(0),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_glow, _pulse]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulse.value,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          PreWorkoutScreen(
                            workoutType: widget.workoutType,
                            duration: widget.duration,
                            soreMuscles: widget.soreMuscles,
                          ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeOutExpo;

                        var tween = Tween(begin: begin, end: end).chain(
                          CurveTween(curve: curve),
                        );

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: canContinue
                          ? [const Color(0xFFD4AF37), const Color(0xFFB8941F)]
                          : [Colors.white, const Color(0xFFE0E0E0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: canContinue
                            ? const Color(0xFFD4AF37).withOpacity(0.3 * _glow.value)
                            : Colors.white.withOpacity(0.2 * _glow.value),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: canContinue
                            ? const Color(0xFFD4AF37).withOpacity(0.15 * _glow.value)
                            : Colors.white.withOpacity(0.1 * _glow.value),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        canContinue ? 'CONTINUE TO WORKOUT' : 'SKIP FOR NOW',
                        style: TextStyle(
                          color: canContinue ? Colors.white : Colors.black,
                          fontSize: 16,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: canContinue
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black.withOpacity(0.8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}