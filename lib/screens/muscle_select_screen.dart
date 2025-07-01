import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:peakfit_frontend/screens/time_select_screen.dart';

class MuscleSelectScreen extends StatefulWidget {
  const MuscleSelectScreen({super.key});
  @override
  State<MuscleSelectScreen> createState() => _MuscleSelectScreenState();
}

/* ▸ mix in TickerProvider so AnimatedSize clips during tween */
class _MuscleSelectScreenState extends State<MuscleSelectScreen>
    with TickerProviderStateMixin {
  // ----------------------------- data
  static const _muscles = [
    'Quads', 'Hamstrings', 'Calves', 'Glutes', 'Hip-flexors', 'Adductors',
    'Lower-back', 'Lats', 'Traps', 'Pecs', 'Delts', 'Biceps',
    'Triceps', 'Forearms', 'Abs', 'Obliques', 'Neck'
  ];
  String? _open;
  final Map<String, int> _scores = {};        // muscle → 1-10

  // ----------------------------- colours
  static const _lightPink = Color(0xFFFFE3E3);
  static const _maroon    = Color(0xFF701818);
  Color _bg(int? s) {
    if (s == null || s == 0) return Colors.white;
    final t = (s - 1) / 9;                    // 1→0 … 10→1
    return Color.lerp(_lightPink, _maroon, t)!;
  }

  // ----------------------------- continue
  Future<void> _next() async {
    try {
      final uid   = FirebaseAuth.instance.currentUser!.uid;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('soreness').doc(today)
          .set(_scores);
    } catch (_) {/* ignore write error during dev */}
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimeSelectScreen()),
    );
  }

  // ----------------------------- UI
  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: const Color(0xFFF5F5F5),
    appBar: AppBar(
      title: const Text('Select sore muscles'),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    body: ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
      itemCount: _muscles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final m     = _muscles[i];
        final open  = m == _open;
        final score = _scores[m];

        return GestureDetector(
          onTap: () => setState(() => _open = open ? null : m),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: Container(
              height: open ? 150 : 72,
              decoration: BoxDecoration(
                color: _bg(score),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              child: open
                  ? _OpenedTile(
                muscle: m,
                initial: score ?? 0,
                onChanged: (v) => setState(() {
                  if (v == 0) {
                    _scores.remove(m);
                  } else {
                    _scores[m] = v;
                  }
                }),
              )
                  : Align(
                alignment: Alignment.centerLeft,
                child: Text(m,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ),
        );
      },
    ),
    bottomNavigationBar: Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: ElevatedButton(
        onPressed: _next,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D3436),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text('Continue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    ),
  );
}

/* ── slider tile ─────────────────────────────────────────────────────── */
class _OpenedTile extends StatefulWidget {
  const _OpenedTile(
      {required this.muscle, required this.initial, required this.onChanged});
  final String muscle;
  final int    initial;
  final ValueChanged<int> onChanged;
  @override
  State<_OpenedTile> createState() => _OpenedTileState();
}

class _OpenedTileState extends State<_OpenedTile> {
  late int _value = widget.initial;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.muscle,
          style:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 22),
      Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.red,
                inactiveTrackColor: Colors.red.withOpacity(.25),
                thumbColor: Colors.red,
                thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 0),
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: Slider(
                min: 0,
                max: 10,
                divisions: 10,
                value: _value.toDouble(),
                onChanged: (v) => setState(() {
                  _value = v.round();
                  widget.onChanged(_value);
                }),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Center(
              child: Text(
                '$_value',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
