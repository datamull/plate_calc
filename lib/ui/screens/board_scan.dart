import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/daily_library.dart';
import '../../l10n/app_localizations.dart';
import '../../services/board_ai.dart';
import '../../services/board_parser.dart';
import '../../services/training_store.dart';
import '../theme/app_theme.dart';
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
    photo = await ImagePicker().pickImage(source: source, maxWidth: 1800, imageQuality: 85);
  } catch (_) {
    if (context.mounted) _snack(context, loc.scanPermission);
    return;
  }
  if (photo == null || !context.mounted) return;

  // Apple (regla 5.1.2(i)): pedir permiso antes de enviar la foto a una IA
  // de terceros. Se pregunta una vez; se cambia en Ajustes.
  var useAi = BoardAi.enabled && store.storage.aiConsent != false;
  if (useAi && store.storage.aiConsent == null) {
    final ok = await askAiConsent(context);
    if (ok == null || !context.mounted) return;
    await store.storage.setAiConsent(ok);
    useAi = ok;
  }
  if (!context.mounted) return;

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
  // 1) IA (Gemini en el servidor). 2) Si no hay internet o falla: lector local.
  var text = '';
  var byAi = false;
  var wod = useAi ? await BoardAi.read(photo.path, fallbackName: loc.scanDefaultName) : null;
  if (wod != null && wod.items.isNotEmpty) {
    byAi = true;
  } else {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(photo.path));
      text = linesTopToBottom(result);
    } catch (_) {
      text = '';
    } finally {
      await recognizer.close();
    }
    wod = BoardParser.parse(text, fallbackName: loc.scanDefaultName);
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  // Aunque no se lea nada se abre la revisión: ahí se puede escribir a mano.
  if (wod.items.isEmpty) _snack(context, loc.scanNothing);
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ScanReviewScreen(
        store: store,
        wod: wod!,
        imagePath: photo!.path,
        rawText: text,
        byAi: byAi,
      ),
    ),
  );
}

/// Pregunta si se puede enviar la foto a Google Gemini. null = canceló.
Future<bool?> askAiConsent(BuildContext context) {
  final loc = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.auto_awesome, color: AppColors.purple),
      title: Text(loc.aiConsentTitle),
      content: Text(loc.aiConsentBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.aiConsentNo)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.aiConsentYes)),
      ],
    ),
  );
}

/// Todas las líneas leídas, de arriba hacia abajo (y de izquierda a derecha
/// si están a la misma altura). ML Kit agrupa por bloques y, con letra a mano,
/// a veces mezcla el orden.
String linesTopToBottom(RecognizedText result) {
  final lines = [for (final b in result.blocks) ...b.lines];
  lines.sort((a, b) {
    final ay = a.boundingBox.center.dy, by = b.boundingBox.center.dy;
    final h = (a.boundingBox.height + b.boundingBox.height) / 4;
    if ((ay - by).abs() > h) return ay.compareTo(by);
    return a.boundingBox.left.compareTo(b.boundingBox.left);
  });
  return lines.map((l) => l.text).join('\n');
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
    this.rawText = '',
    this.byAi = false,
  });

  final TrainingStore store;
  final DailyWorkout wod;
  final String imagePath;

  /// Texto tal como lo leyó la cámara (para revisar qué entendió).
  final String rawText;

  /// true si la leyó la IA (se muestra una etiqueta).
  final bool byAi;

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

  /// Editar (o agregar, si [index] es null) un ejercicio.
  Future<void> _edit(int? index) async {
    final edited = await showDialog<DailyItem>(
      context: context,
      builder: (_) => _ItemEditor(item: index == null ? null : _items[index]),
    );
    if (edited == null) return;
    setState(() => index == null ? _items.add(edited) : _items[index] = edited);
  }

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
          if (widget.byAi)
            Padding(
              padding: const EdgeInsets.fromLTRB(Ds.gutter, 0, Ds.gutter, 8),
              child: Row(children: [DsPill(loc.scanByAi, color: AppColors.purple)]),
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
                for (var i = 0; i < _items.length; i++)
                  InkWell(
                    onTap: () => _edit(i),
                    child: Row(
                      children: [
                        Expanded(
                          child: WodItemRow(item: _items[i], store: widget.store, unit: unit),
                        ),
                        IconButton(
                          tooltip: loc.delete,
                          icon: Icon(Icons.close, size: 18, color: Ds.muted(context)),
                          onPressed: () => setState(() => _items.removeAt(i)),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(loc.workoutAddExercise),
                    onPressed: () => _edit(null),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Ds.gutter, 8, Ds.gutter, 0),
            child: Text(loc.scanTapToEdit, style: Ds.secondary(context)),
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
          if (widget.rawText.trim().isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(loc.scanRawText, style: Ds.secondary(context)),
                childrenPadding: const EdgeInsets.fromLTRB(Ds.gutter, 0, Ds.gutter, 16),
                expandedAlignment: Alignment.centerLeft,
                children: [SelectableText(widget.rawText, style: Ds.secondary(context))],
              ),
            ),
        ],
      ),
    );
  }
}

/// Diálogo para corregir un ejercicio leído de la pizarra.
class _ItemEditor extends StatefulWidget {
  const _ItemEditor({this.item});

  final DailyItem? item;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late final _reps = TextEditingController(text: widget.item?.reps ?? '');
  late final _rx = TextEditingController(text: widget.item?.rxKg ?? widget.item?.rxLb ?? '');
  late String _move = widget.item?.lift ?? '';

  @override
  void dispose() {
    _reps.dispose();
    _rx.dispose();
    super.dispose();
  }

  void _save() {
    final move = _move.trim();
    if (move.isEmpty) return;
    final known = BoardParser.matchMove(move);
    final lift = known ?? move;
    final rx = _rx.text.trim();
    final old = widget.item;
    Navigator.pop(
      context,
      DailyItem(
        lift,
        reps: _reps.text.trim(),
        sets: old?.sets,
        repsPerSet: old?.repsPerSet,
        percent: old?.lift == lift ? old?.percent : null,
        rmOf: known == null ? null : BoardParser.rmOf(known),
        rxKg: rx.isEmpty ? null : rx,
        rxLb: rx.isEmpty ? null : rx,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.item == null ? loc.workoutAddExercise : loc.edit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _reps,
              decoration: InputDecoration(
                labelText: loc.scanRepsLabel,
                hintText: '21-15-9, 400 m, 15',
              ),
            ),
            const SizedBox(height: 12),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _move),
              optionsBuilder: (v) {
                final q = v.text.trim().toLowerCase();
                if (q.isEmpty) return const Iterable<String>.empty();
                return BoardParser.knownMoves.where((m) => m.toLowerCase().contains(q)).take(8);
              },
              onSelected: (m) => _move = m,
              fieldViewBuilder: (context, ctrl, focus, onSubmit) => TextField(
                controller: ctrl,
                focusNode: focus,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: loc.scanMoveLabel),
                onChanged: (v) => _move = v,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rx,
              decoration: InputDecoration(labelText: loc.scanRxLabel, hintText: '24/16'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
        FilledButton(onPressed: _save, child: Text(loc.save)),
      ],
    );
  }
}
