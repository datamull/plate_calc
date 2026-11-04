import '../data/daily_library.dart';

/// Convierte el texto leído de una pizarra (foto + ML Kit) en un WOD.
///
/// Reconoce:
///  - formato: AMRAP 12, EMOM 10, For Time, 5 RFT / 5 rounds, time cap;
///  - repeticiones al inicio o al final: "21-15-9", "400 m", "15/12 cal",
///    "Burpees x 10", "5x5 Back Squat";
///  - movimientos y abreviaturas comunes (T2B, DU, KBS, HSPU, C2B, OHS...),
///    en inglés, español y francés, tolerando errores de lectura;
///  - pesos Rx "95/65 lb", "43/29 kg" y porcentajes "@ 75%".
class BoardParser {
  BoardParser._();

  /// Movimiento → (alias en minúsculas, RM de referencia para el %).
  static const _moves = <String, (List<String>, String?)>{
    'Snatch': (['snatch', 'arranque', 'arraché', 'arrache', 'sn'], null),
    'Power Snatch': (['power snatch', 'psn', 'p snatch'], 'Snatch'),
    'Hang Power Snatch': (['hang power snatch', 'hps', 'hang snatch'], 'Snatch'),
    'Clean': (['clean', 'cargada', 'épaulé', 'epaule', 'squat clean'], null),
    'Power Clean': (['power clean', 'pc', 'p clean'], 'Clean'),
    'Hang Power Clean': (['hang power clean', 'hpc', 'hang clean'], 'Clean'),
    'Clean & Jerk': (['clean and jerk', 'clean & jerk', 'c&j', 'cj', 'envion', 'envión'], 'Clean'),
    'Jerk': (['jerk', 'split jerk', 'push jerk', 'jeté', 'jete'], null),
    'Push Press': (['push press', 'pp'], 'Jerk'),
    'Shoulder-to-Overhead': (['shoulder to overhead', 's2oh', 'stoh', 'sto'], 'Jerk'),
    'Overhead Press': (
      ['overhead press', 'strict press', 'shoulder press', 'press militar', 'ohp'],
      null,
    ),
    'Thruster': (['thruster', 'thrusters'], 'Front Squat'),
    'Back Squat': (['back squat', 'bs', 'sentadilla trasera', 'squat arrière'], null),
    'Front Squat': (['front squat', 'fs', 'sentadilla frontal', 'squat avant'], null),
    'Overhead Squat': (['overhead squat', 'ohs'], 'Snatch'),
    'Air Squat': (
      ['air squat', 'air squats', 'squat', 'squats', 'sentadillas', 'sentadilla'],
      null,
    ),
    'Deadlift': (['deadlift', 'dl', 'peso muerto', 'soulevé de terre', 'souleve de terre'], null),
    'Sumo Deadlift High Pull': (['sumo deadlift high pull', 'sdhp'], 'Deadlift'),
    'Bench Press': (['bench press', 'bench', 'press banca', 'développé couché'], null),
    'Pull-Up': (
      ['pull up', 'pull-up', 'pullup', 'pull ups', 'dominadas', 'dominada', 'tractions'],
      null,
    ),
    'Chest-to-Bar Pull-Up': (['chest to bar', 'c2b', 'ctb', 'chest-to-bar'], null),
    'Toes-to-Bar': (['toes to bar', 't2b', 'ttb', 'toes-to-bar', 'pies a la barra'], null),
    'Muscle-Up': (['muscle up', 'muscle-up', 'mu', 'ring muscle up', 'rmu'], null),
    'Bar Muscle-Up': (['bar muscle up', 'bmu', 'bar mu'], null),
    'Handstand Push-Up': (['handstand push up', 'hspu', 'handstand push-up'], null),
    'Push-Up': (['push up', 'push-up', 'pushup', 'push ups', 'flexiones', 'pompes'], null),
    'Burpee': (['burpee', 'burpees'], null),
    'Bar-Facing Burpee': (['bar facing burpee', 'bfb', 'bar-facing burpee'], null),
    'Burpee Box Jump': (['burpee box jump', 'bbj', 'burpee box jump over', 'bbjo'], null),
    'Box Jump': (['box jump', 'box jumps', 'bj', 'salto al cajón', 'salto cajon'], null),
    'Box Jump Over': (['box jump over', 'bjo'], null),
    'Wall Ball': (['wall ball', 'wall balls', 'wb', 'wallball', 'wall ball shot'], null),
    'Kettlebell Swing': (
      ['kettlebell swing', 'kb swing', 'kbs', 'swings', 'russian swing', 'american swing'],
      null,
    ),
    'Double Under': (
      ['double under', 'double unders', 'du', 'dus', 'dobles', 'saltos dobles'],
      null,
    ),
    'Single Under': (['single under', 'single unders', 'su'], null),
    'Sit-Up': (['sit up', 'sit-up', 'situp', 'sit ups', 'abmat', 'abdominales'], null),
    'Lunge': (['lunge', 'lunges', 'walking lunge', 'estocadas', 'fentes'], null),
    'Dumbbell Snatch': (['dumbbell snatch', 'db snatch', 'dbs'], null),
    'Devil Press': (['devil press', 'devils press'], null),
    'Ring Dip': (['ring dip', 'ring dips', 'dips', 'fondos'], null),
    'Rope Climb': (['rope climb', 'rope climbs', 'rc', 'trepa', 'cuerda'], null),
    'Row': (['row', 'rower', 'remo', 'rameur', 'cal row', 'row cal'], null),
    'Bike': (['bike', 'assault bike', 'echo bike', 'airbike', 'bici'], null),
    'Ski': (['ski', 'ski erg', 'skierg'], null),
    'Run': (['run', 'running', 'correr', 'carrera', 'course'], null),
  };

  static final _alias = <String, String>{
    for (final e in _moves.entries)
      for (final a in [e.key.toLowerCase(), ...e.value.$1]) _norm(a): e.key,
  };

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[-_.,:;()*•·]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String? rmOf(String move) => _moves[move]?.$2;

  /// Busca el movimiento en [text]: exacto, el alias más largo contenido, o
  /// con hasta 2 letras distintas (errores de lectura de la foto).
  static String? matchMove(String text) {
    final n = _norm(text);
    if (n.isEmpty) return null;
    if (_alias[n] != null) return _alias[n];
    // Sin la "s" final (plurales).
    final singular = n.endsWith('s') ? n.substring(0, n.length - 1) : n;
    if (_alias[singular] != null) return _alias[singular];
    String? best;
    var bestLen = 0;
    for (final e in _alias.entries) {
      final a = e.key;
      if (a.length < 3 && a != n) continue; // abreviaturas cortas solo exactas
      if (RegExp('(^| )${RegExp.escape(a)}( |\$)').hasMatch(n) && a.length > bestLen) {
        best = e.value;
        bestLen = a.length;
      }
    }
    if (best != null) return best;
    if (n.length >= 5) {
      for (final e in _alias.entries) {
        if (e.key.length >= 5 && _lev(n, e.key) <= 2) return e.value;
      }
    }
    return null;
  }

  static int _lev(String a, String b) {
    if ((a.length - b.length).abs() > 2) return 99;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = [i, ...List<int>.filled(b.length, 0)];
      for (var j = 1; j <= b.length; j++) {
        cur[j] = [
          prev[j] + 1,
          cur[j - 1] + 1,
          prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
        ].reduce((x, y) => x < y ? x : y);
      }
      prev = cur;
    }
    return prev[b.length];
  }

  static final _amrap = RegExp(
    r'amrap\s*(?:of\s*|de\s*)?(\d+)|(\d+)\s*(?:min|minutes|minutos|′|\x27)?\s*amrap',
    caseSensitive: false,
  );
  static final _emom = RegExp(
    r'e(?:\d)?mom\s*(?:x\s*)?(\d+)|(\d+)\s*(?:min|minutes|minutos|′|\x27)?\s*e(?:\d)?mom',
    caseSensitive: false,
  );
  static final _rounds = RegExp(
    r'(\d+)\s*(?:rounds?|rds?|rft|rondas?|tours?)\b',
    caseSensitive: false,
  );
  static final _forTime = RegExp(
    r'for\s*time|por\s*tiempo|pour\s*(?:le\s*)?temps|\bft\b',
    caseSensitive: false,
  );
  static final _cap = RegExp(r'(?:time\s*cap|cap|tc)\s*[:=]?\s*(\d+)', caseSensitive: false);
  static final _setsReps = RegExp(r'^(\d+)\s*[x×]\s*(\d+)\b\s*(.*)$', caseSensitive: false);
  static final _leadReps = RegExp(
    r'^((?:\d+\s*[-/]\s*)*\d+\s*(?:m\b|km\b|cal(?:s|ories)?\b|reps?\b)?)\s*[x×]?\s*(.+)$',
    caseSensitive: false,
  );
  static final _tailReps = RegExp(
    r'^(.+?)\s*[x×:]?\s*((?:\d+\s*[-/]\s*)*\d+\s*(?:m|cal|reps?)?)$',
    caseSensitive: false,
  );
  static final _rx = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*/\s*(\d+(?:[.,]\d+)?)\s*(kg|kgs|lb|lbs|#|cm|in|")?',
    caseSensitive: false,
  );
  static final _pct = RegExp(r'@?\s*(\d{2,3})\s*%');

  static DailyWorkout parse(String text, {required String fallbackName}) {
    final lines = text
        .split(RegExp(r'[\n\r]+'))
        .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final all = lines.join('\n');

    int? minutes;
    int? rounds;
    var format = WodFormat.forTime;
    final am = _amrap.firstMatch(all);
    final em = _emom.firstMatch(all);
    if (am != null) {
      format = WodFormat.amrap;
      minutes = int.tryParse(am.group(1) ?? am.group(2) ?? '');
    } else if (em != null) {
      format = WodFormat.emom;
      minutes = int.tryParse(em.group(1) ?? em.group(2) ?? '');
    } else {
      final rm = _rounds.firstMatch(all);
      if (rm != null) rounds = int.tryParse(rm.group(1)!);
      final cap = _cap.firstMatch(all);
      if (cap != null) minutes = int.tryParse(cap.group(1)!);
    }

    String? name;
    final items = <DailyItem>[];
    var setsLines = 0;
    for (final raw in lines) {
      // Líneas que solo dicen el formato.
      final stripped = raw
          .replaceAll(_amrap, '')
          .replaceAll(_emom, '')
          .replaceAll(_rounds, '')
          .replaceAll(_forTime, '')
          .replaceAll(_cap, '')
          .replaceAll(RegExp(r'\b(?:min|minutes|minutos|of|de)\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'[:\-–—]+'), ' ')
          .trim();
      if (stripped.isEmpty) continue;

      var line = stripped;
      String? rxKg, rxLb;
      final rx = _rx.firstMatch(line);
      if (rx != null) {
        final unit = (rx.group(3) ?? '').toLowerCase();
        final v = '${rx.group(1)}/${rx.group(2)}';
        if (unit.startsWith('lb') || unit == '#') {
          rxLb = v;
        } else if (unit == 'cm' || unit == 'in' || unit == '"') {
          rxKg = '$v $unit';
          rxLb = '$v $unit';
        } else {
          rxKg = v;
        }
        line = line.replaceRange(rx.start, rx.end, ' ').trim();
      }
      double? pct;
      final pm = _pct.firstMatch(line);
      if (pm != null) {
        pct = double.tryParse(pm.group(1)!);
        line = line.replaceRange(pm.start, pm.end, ' ').trim();
      }
      line = line.replaceAll(RegExp(r'\s+@\s*$'), '').trim();

      String reps = '';
      String move = line;
      int? sets, perSet;
      final sr = _setsReps.firstMatch(line);
      if (sr != null) {
        sets = int.tryParse(sr.group(1)!);
        perSet = int.tryParse(sr.group(2)!);
        reps = '$sets×$perSet';
        move = sr.group(3)!;
        setsLines++;
      } else {
        final lr = _leadReps.firstMatch(line);
        if (lr != null && RegExp(r'[a-zA-Z]').hasMatch(lr.group(2)!)) {
          reps = lr.group(1)!.replaceAll(' ', '');
          move = lr.group(2)!;
        } else {
          final tr = _tailReps.firstMatch(line);
          if (tr != null && RegExp(r'[a-zA-Z]').hasMatch(tr.group(1)!)) {
            reps = tr.group(2)!.replaceAll(' ', '');
            move = tr.group(1)!;
          }
        }
      }

      final known = matchMove(move);
      if (known == null && reps.isEmpty) {
        // Sin movimiento ni reps: probablemente el título.
        if (name == null && items.isEmpty && move.length <= 30) name = _title(move);
        continue;
      }
      if (known == null && !RegExp(r'[a-zA-Z]{2}').hasMatch(move)) continue;
      items.add(
        DailyItem(
          known ?? _title(move),
          reps: reps,
          sets: sets,
          repsPerSet: perSet,
          percent: pct,
          rmOf: known == null ? null : rmOf(known),
          rxKg: rxKg,
          rxLb: rxLb,
        ),
      );
    }

    // Solo series × reps (fuerza): se registra por series.
    if (am == null && em == null && rounds == null && setsLines > 0 && setsLines == items.length) {
      format = WodFormat.sets;
    }

    return DailyWorkout(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      style: TrainingStyle.crossfit,
      name: name ?? fallbackName,
      format: format,
      items: items,
      minutes: minutes,
      rounds: rounds,
      score: switch (format) {
        WodFormat.forTime => ScoreType.time,
        WodFormat.amrap => ScoreType.rounds,
        WodFormat.emom => ScoreType.none,
        WodFormat.sets => ScoreType.load,
      },
    );
  }

  static String _title(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}
