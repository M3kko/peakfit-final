import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'home_screen.dart';           // ⬅️  add this line

// ---------------------------------------------------------------------------
// WeeklyPlanScreen – compact minimalist list with icon avatars
// ---------------------------------------------------------------------------
class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});
  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _plan;

  @override
  void initState() {
    super.initState();
    _fetchPlan();
  }

  Future<void> _fetchPlan() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('generateWeeklyPlan');
      final result = await callable.call(<String, dynamic>{'userId': user.uid});

      final wrapper = Map<String, dynamic>.from(result.data as Map);
      final plan = Map<String, dynamic>.from(wrapper['weeklyPlan'] as Map);
      plan['days'] = (plan['days'] as List)
          .map((d) => Map<String, dynamic>.from(d as Map))
          .toList();

      if (!mounted) return;
      setState(() {
        _plan = plan;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Weekly Plan', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _PlanList(days: List<Map<String, dynamic>>.from(_plan!['days'])),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () {
            // ⬇️  push HomeScreen and discard WeeklyPlanScreen from the stack
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D3436),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _PlanList extends StatelessWidget {
  const _PlanList({required this.days});
  final List<Map<String, dynamic>> days;

  static const _weekdayOrder = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  Color _accentForName(String name) {
    if (name.contains('Recovery')) return const Color(0xFF6FCF97);
    if (name.contains('Strength') || name.contains('Power')) return const Color(0xFFEB5757);
    return const Color(0xFF2D9CDB);
  }

  IconData _iconForName(String name) {
    if (name.contains('Recovery')) return Icons.self_improvement;
    if (name.contains('Strength') || name.contains('Power')) return Icons.fitness_center;
    if (name.contains('Circuit') || name.contains('Performance')) return Icons.directions_run;
    return Icons.sports_gymnastics;
  }

  @override
  Widget build(BuildContext context) {
    days.sort((a, b) =>
        _weekdayOrder.indexOf(a['day']).compareTo(_weekdayOrder.indexOf(b['day'])));

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final day = days[i];
        final accent = _accentForName(day['name']);
        final icon = _iconForName(day['name']);
        final title = '${day['day'].substring(0, 3)} – ${day['name']}';

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          elevation: 1,
          child: Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _IconCircle(accent: accent, icon: icon),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        (day['focus'] as List).join(', '),
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.accent, required this.icon});
  final Color accent;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration:
    BoxDecoration(color: accent.withOpacity(.15), shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Icon(icon, color: accent, size: 28),
  );
}
