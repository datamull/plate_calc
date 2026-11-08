import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/daily_library.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../services/training_store.dart';
import '../../utils/format.dart';
import '../theme/app_theme.dart';
import '../widgets/ds.dart';
import 'workout_detail_screen.dart';

/// Un WOD con reloj: cronómetro (For Time), cuenta regresiva (AMRAP) o
/// minuto a minuto (EMOM). Al terminar se anota el resultado.
class WodScreen extends StatefulWidget {
  const WodScreen({super.key, required this.store, required this.wod});

  final TrainingStore store;
  final DailyWorkout wod;

  @override
  State<WodScreen> createState() => _WodScreenState();
}

class _WodScreenState extends State<WodScreen> {
  DailyWorkout get _wod => widget.wod;
  Timer? _timer;
  int _elapsed = 0;
  bool _running = false;

  int? get _total => _wod.minutes == null ? null : _wod.minutes! * 60;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _elapsed++);
    final total = _total;
    // Nuevo minuto en EMOM.
    if (_wod.format == WodFormat.emom && _elapsed % 60 == 0) HapticFeedback.heavyImpact();
    if (total != null && _elapsed >= total) {
      _timer?.cancel();
      _running = false;
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      _finish();
    }
  }

  /// Texto grande del reloj.
  String get _clock {
    final total = _total;
    return switch (_wod.format) {
      WodFormat.amrap when total != null => fmtClock(total - _elapsed),
      WodFormat.emom => fmtClock(60 - _elapsed % 60),
      _ => fmtClock(_elapsed),
    };
  }

  Future<void> _finish() async {
    _timer?.cancel();
    setState(() => _running = false);
    final loc = AppLocalizations.of(context);
    final score = await showDialog<String>(
      context: context,
      builder: (_) => _ScoreDialog(wod: _wod, elapsed: _elapsed),
    );
    if (score == null || !mounted) return;
    final saved = await widget.store.saveWodResult(
      _wod,
      widget.store.storage.listUnit,
      score: score,
      durationSec: _elapsed,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.wodSaved(score))));
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutDetailScreen(store: widget.store, workoutId: saved.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final unit = widget.store.storage.listUnit;
    final emomRound = _wod.format == WodFormat.emom && _wod.minutes != null
        ? '${loc.wodRound} ${(_elapsed ~/ 60 + 1).clamp(1, _wod.minutes!)} / ${_wod.minutes}'
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(_wod.name)),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            DsPill(_wod.formatLabel, color: const Color(0xFFFF7A3D)),
            const SizedBox(height: 12),
            Text(_clock, style: Ds.display(context).copyWith(fontSize: 88, letterSpacing: -2)),
            if (emomRound != null)
              Text(emomRound, style: Ds.secondary(context).copyWith(fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: DsBlock(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final item in _wod.items)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            border: item == _wod.items.first
                                ? null
                                : Border(top: BorderSide(color: Ds.hairline(context))),
                          ),
                          child: Row(
                            children: [
                              if (item.reps.isNotEmpty)
                                ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 56),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Text(
                                      item.reps,
                                      style: Ds.body(context).copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontFeatures: Ds.tabular,
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(liftDisplayName(item.lift), style: Ds.body(context)),
                              ),
                              Builder(
                                builder: (context) {
                                  final w = widget.store.dailyWeight(item, unit);
                                  final t = w != null
                                      ? '${fmtWeight(w)} ${unit.label}'
                                      : item.rx(unit);
                                  return t == null
                                      ? const SizedBox()
                                      : Text(
                                          t,
                                          style: Ds.body(context).copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontFeatures: Ds.tabular,
                                          ),
                                        );
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _running ? const Color(0xFF3A404C) : AppColors.blue,
                        minimumSize: const Size.fromHeight(60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: Text(
                        _running ? loc.wodPause : (_elapsed == 0 ? loc.wodGo : loc.wodContinue),
                      ),
                      onPressed: _toggle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Ds.done,
                        minimumSize: const Size.fromHeight(60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      icon: const Icon(Icons.flag_rounded),
                      label: Text(loc.workoutFinishShort),
                      onPressed: _finish,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

String fmtClock(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Anotar el resultado: tiempo (For Time), rondas + reps (AMRAP) o libre.
class _ScoreDialog extends StatefulWidget {
  const _ScoreDialog({required this.wod, required this.elapsed});

  final DailyWorkout wod;
  final int elapsed;

  @override
  State<_ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends State<_ScoreDialog> {
  late final _a = TextEditingController(
    text: widget.wod.score == ScoreType.time ? fmtClock(widget.elapsed) : '',
  );
  final _b = TextEditingController();

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  String? get _score {
    final a = _a.text.trim();
    final b = _b.text.trim();
    return switch (widget.wod.score) {
      ScoreType.time => a.isEmpty ? null : a,
      ScoreType.rounds => a.isEmpty ? null : (b.isEmpty || b == '0' ? '$a rds' : '$a rds + $b'),
      _ => a.isEmpty ? '✓' : a,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final type = widget.wod.score;
    return AlertDialog(
      title: Text(loc.wodScoreTitle),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _a,
              autofocus: true,
              keyboardType: type == ScoreType.time
                  ? TextInputType.datetime
                  : const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: switch (type) {
                  ScoreType.time => loc.wodScoreTime,
                  ScoreType.rounds => loc.wodScoreRounds,
                  _ => loc.workoutNotes,
                },
              ),
            ),
          ),
          if (type == ScoreType.rounds) ...[
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _b,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: loc.wodScoreReps),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
        FilledButton(
          onPressed: () {
            final s = _score;
            if (s != null) Navigator.pop(context, s);
          },
          child: Text(loc.save),
        ),
      ],
    );
  }
}
