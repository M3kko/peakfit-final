import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:peakfit_frontend/screens/whoop_connect_screen.dart';

class TimeSelectScreen extends StatefulWidget {
  const TimeSelectScreen({super.key});
  @override
  State<TimeSelectScreen> createState() => _TimeSelectScreenState();
}

class _TimeSelectScreenState extends State<TimeSelectScreen>
    with SingleTickerProviderStateMixin {
  // ----------------------------- data
  static const _minTime = 15;
  static const _maxTime = 60;
  static const _increment = 5;

  int _selectedMinutes = _minTime;
  late AnimationController _animController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Calculate progress (0.0 at 15m, 1.0 at 60m)
  double get _progress => (_selectedMinutes - _minTime) / (_maxTime - _minTime);

  void _updateTime(int newTime) {
    if (newTime < _minTime || newTime > _maxTime) return;

    setState(() {
      _progressAnimation = Tween<double>(
        begin: _progress,
        end: (newTime - _minTime) / (_maxTime - _minTime),
      ).animate(CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOut,
      ));
      _selectedMinutes = newTime;
      _animController.forward(from: 0);
    });
  }

  // ----------------------------- continue
  Future<void> _next() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('workouts').doc(today)
          .set({
        'availableTime': _selectedMinutes,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {/* ignore write error during dev */}

    if (!mounted) return;
    // Navigator.push(
     //  context,
     //  MaterialPageRoute(builder: (_) => const WhoopConnectScreen()),
   //  );
  }

  // ----------------------------- UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Title
            const Text(
              'Workout Duration',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'How much time do you have?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E93),
              ),
            ),

            const Spacer(),

            // Circular progress with time display
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  CustomPaint(
                    size: const Size(280, 280),
                    painter: CircularProgressPainter(
                      progress: _progress,
                      backgroundColor: const Color(0xFFF2F2F7),
                      progressColor: Colors.black,
                      strokeWidth: 8,
                    ),
                  ),

                  // Time display
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_selectedMinutes',
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w300,
                          color: Colors.black,
                          letterSpacing: -3,
                          height: 1,
                        ),
                      ),
                      const Text(
                        'minutes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8E8E93),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),

                  // Increment/Decrement buttons
                  Positioned(
                    left: 20,
                    child: _CircleButton(
                      icon: Icons.remove,
                      onTap: () => _updateTime(_selectedMinutes - _increment),
                      enabled: _selectedMinutes > _minTime,
                    ),
                  ),
                  Positioned(
                    right: 20,
                    child: _CircleButton(
                      icon: Icons.add,
                      onTap: () => _updateTime(_selectedMinutes + _increment),
                      enabled: _selectedMinutes < _maxTime,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Quick select chips
            Wrap(
              spacing: 12,
              children: [15, 30, 45, 60].map((time) =>
                  GestureDetector(
                    onTap: () => _updateTime(time),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedMinutes == time
                            ? Colors.black
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${time}m',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _selectedMinutes == time
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
              ).toList(),
            ),

            const Spacer(),

            // Continue button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextButton(
                onPressed: _next,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Custom painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Circle button widget
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? Colors.black : const Color(0xFFF2F2F7),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : const Color(0xFFC7C7CC),
          size: 20,
        ),
      ),
    );
  }
}