import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/daily_library.dart';
import '../../l10n/app_localizations.dart';
import '../../services/board_parser.dart';
import '../../services/training_store.dart';
import '../widgets/ds.dart';
import 'training_home.dart';
import 'wod_screen.dart';
import 'workout_screen.dart';

/// Foto de una pizarra → texto (ML Kit, en el teléfono, sin internet) →
/// WOD para revisar y empezar.
Future<void> scanBoard(BuildContext context, TrainingStore store) async {
  final loc = AppLocalizations.of(context);
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(loc.scanCamera),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(loc.scanGallery),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return;

  XFile? photo;
  try {
    photo = await ImagePicker().pickImage(source: source, maxWidth: 2400, imageQuality: 92);
  } catch (_) {
    if (context.mounted) _snack(context, loc.scanPermission);
    return;
  }
  if (photo == null || !context.mounted) return;

  // Lectura con indicador de espera (se cierra al terminar).
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(loc.scanReading)),
            ],
          ),
        ),
      ),
    ),
  );
  String text = '';
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(InputImage.fromFilePath(photo.path));
    text = result.text;
  } catch (_) {
    text = '';
  } finally {
    await recognizer.close();
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  final wod = BoardParser.parse(text, fallbackName: loc.scanDefaultName);
  if (wod.items.isEmpty) {
    _snack(context, loc.scanNothing);
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ScanReviewScreen(store: store, wod: wod, imagePath: photo!.path),
    ),
  );
}

void _snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

/// Empieza un WOD: con reloj (AMRAP, EMOM, For Time) o por series.
Future<void> startWod(BuildContext context, TrainingStore store, DailyWorkout d) {
  final timed = d.format != WodFormat.sets;
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => timed
          ? WodScreen(store: store, wod: d)
          : WorkoutScreen(store: store, workout: store.startDaily(d, store.storage.listUnit)),
    ),
  );
}

/// Revisar lo que se leyó de la pizarra: corregir formato y minutos, quitar
/// filas mal leídas y empezar.
class ScanReviewScreen extends StatefulWidget {
  const ScanReviewScreen({
    super.key,
    required this.store,
    required this.wod,
    required this.imagePath,
  });

  final TrainingStore store;
  final DailyWorkout wod;
  final String imagePath;

  @override
  State<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends State<ScanReviewScreen> {
  late WodFormat _format = widget.wod.format;
  late final _name = TextEditingController(text: widget.wod.name);
  late final _minutes = TextEditingController(
    text: widget.wod.minutes == null ? '' : '${widget.wod.minutes}',
  );
  late final _rounds = TextEditingController(
    text: widget.wod.rounds == null ? '' : '${widget.wod.rounds}',
  );
  late final List<DailyItem> _items = [...widget.wod.items];

  @override
  void dispose() {
    _name.dispose();
    _minutes.dispose();
    _rounds.dispose();
    super.dispose();
  }

  DailyWorkout get _wod => DailyWorkout(
    id: widget.wod.id,
    style: TrainingStyle.crossfit,
    name: _name.text.trim().isEmpty ? widget.wod.name : _name.text.trim(),
    format: _format,
    items: _items,
    minutes: int.tryParse(_minutes.text.trim()),
    rounds: _format == WodFormat.forTime ? int.tryParse(_rounds.text.trim()) : null,
    score: switch (_format) {
      WodFormat.forTime => ScoreType.time,
      WodFormat.amrap => ScoreType.rounds,
      WodFormat.emom => ScoreType.none,
      WodFormat.sets => ScoreType.load,
    },
  );

  bool get _needsMinutes =>
      (_format == WodFormat.amrap || _format == WodFormat.emom) &&
      (int.tryParse(_minutes.text.trim()) ?? 0) <= 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final unit = widget.store.storage.listUnit;
    final wod = _wod;

    return Scaffold(
      appBar: AppBar(title: Text(loc.scanTitle)),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(widget.imagePath),
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(height: 0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Ds.gutter, 0, Ds.gutter, 12),
            child: Text(loc.scanCheck, style: Ds.secondary(context)),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in WodFormat.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(switch (f) {
                        WodFormat.forTime => 'For Time',
                        WodFormat.amrap => 'AMRAP',
                        WodFormat.emom => 'EMOM',
                        WodFormat.sets => loc.planSets,
                      }),
                      selected: f == _format,
                      showCheckmark: false,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      onSelected: (_) => setState(() => _format = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _name,
                    decoration: InputDecoration(labelText: loc.planNameLabel),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_format != WodFormat.sets) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _minutes,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _format == WodFormat.forTime ? 'Cap′' : 'Min',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
                if (_format == WodFormat.forTime) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _rounds,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: loc.wodScoreRounds),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          DsBlock(
            padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
            child: Column(
              children: [
                for (final item in _items)
                  Row(
                    children: [
                      Expanded(
                        child: WodItemRow(item: item, store: widget.store, unit: unit),
                      ),
                      IconButton(
                        tooltip: loc.delete,
                        icon: Icon(Icons.close, size: 18, color: Ds.muted(context)),
                        onPressed: () => setState(() => _items.remove(item)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DsPrimaryButton(
            label: loc.todayStart,
            onPressed: _items.isEmpty || _needsMinutes
                ? null
                : () async {
                    final nav = Navigator.of(context);
                    await startWod(context, widget.store, wod);
                    nav.pop();
                  },
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(loc.scanRetake),
              onPressed: () async {
                final nav = Navigator.of(context);
                nav.pop();
                await scanBoard(nav.context, widget.store);
              },
            ),
          ),
        ],
      ),
    );
  }
}
