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
    'Bar Muscle-Up': (['bar muscle up', 'bmu', 'bar mu', 'bmus'], null),
    'Handstand Push-Up': (['handstand push up', 'hspu', 'handstand push-up'], null),
    'Push-Up': (['push up', 'push-up', 'pushup', 'push ups', 'flexiones', 'pompes'], null),
    'Burpee': (['burpee', 'burpees'], null),
    'Bar-Facing Burpee': (['bar facing burpee', 'bfb', 'bar-facing burpee'], null),
    'Burpee Box Jump': (['burpee box jump', 'bbj', 'burpee box jump over', 'bbjo'], null),
    'Box Jump': (['box jump', 'box jumps', 'bj', 'salto al cajón', 'salto cajon'], null),
    'Box Jump Over': (['box jump over', 'bjo'], null),
    'Wall Ball': (
      ['wall ball', 'wall balls', 'wb', 'wbs', 'vvb', 'wallball', 'wall ball shot'],
      null,
    ),
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
    'Dumbbell Snatch': (
      ['dumbbell snatch', 'db snatch', 'dbs', 'db sn', 'mancuerna arranque'],
      null,
    ),
    'Dumbbell Lunge': (['dumbbell lunge', 'db lunge', 'db lunges', 'db walking lunge'], null),
    'Dumbbell Thruster': (['dumbbell thruster', 'db thruster', 'db thrusters'], null),
    'Devil Press': (['devil press', 'devils press'], null),
    'Ring Dip': (['ring dip', 'ring dips', 'dips', 'fondos'], null),
    'Rope Climb': (['rope climb', 'rope climbs', 'rc', 'trepa', 'cuerda'], null),
    'Row': (['row', 'rower', 'remo', 'rameur', 'cal row', 'row cal', 'calrow'], null),
    'Bike': (
      [
        'bike',
        'assault bike',
        'echo bike',
        'echo',
        'cal echo',
        'cal bike',
        'airbike',
        'bici',
        'assault',
      ],
      null,
    ),
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

  /// Nombres de todos los movimientos que reconoce (para sugerencias).
  static List<String> get knownMoves => _moves.keys.toList()..sort();

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
    // Errores de lectura: el alias más parecido (y el más largo si empatan).
    String? fuzzy;
    var fuzzyD = 99, fuzzyLen = 0;
    for (final e in _alias.entries) {
      final a = e.key;
      final max = n.length >= 5 && a.length >= 5
          ? 2
          : (n.length >= 3 && a.length == n.length && !n.contains(' ') ? 1 : 0);
      if (max == 0) continue;
      final d = _lev(n, a);
      if (d <= max && (d < fuzzyD || (d == fuzzyD && a.length > fuzzyLen))) {
        fuzzy = e.value;
        fuzzyD = d;
        fuzzyLen = a.length;
      }
    }
    return fuzzy;
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
    r'a[mn]rap\s*(?:of\s*|de\s*)?(\d[0-9OoZzSsl]?\d?)|(\d+)\s*(?:min|minutes|minutos|′|\x27)?\s*a[mn]rap',
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

  /// Palabras de logos, discos y marcas que aparecen en las fotos.
  static const _noise = {
    'crossfit',
    'club',
    'competition',
    'lb',
    'lbs',
    'kg',
    'kgs',
    'rogue',
    'eleiko',
    'concept',
    'gym',
    'box',
    'wod',
    'by',
    'the',
    'and',
  };

  /// Letras que la lectura confunde con números (O→0, l→1, S→5, Z→2).
  static String _digits(String t) => t
      .replaceAll(RegExp('[Oo]'), '0')
      .replaceAll(RegExp(r'[Il|]'), '1')
      .replaceAll(RegExp('[Ss]'), '5')
      .replaceAll(RegExp('[Zz]'), '2');

  static final _fuzzyNum = RegExp(r'^[0-9OoIl|SsZz]{1,3}$');

  /// Arregla una línea leída de la foto: ruido al inicio, números con
  /// letras ("4O", "lO", "S0"), palabras pegadas ("calrow", "dbsnatch").
  static String _clean(String l) {
    var line = l.replaceAll(RegExp(r'\s+'), ' ').trim();
    // "+00" suele ser un "1" con una mancha delante.
    line = line.replaceFirst(RegExp(r'^\+(?=\d)'), '1');
    line = line.replaceFirst(RegExp(r'^[\-~¬•·*_.,]+\s*'), '');
    final first = line.split(' ').first;
    if (first.length >= 2 &&
        _fuzzyNum.hasMatch(first) &&
        RegExp('[0-9Oo]').hasMatch(first) &&
        line.length > first.length) {
      line = _digits(first) + line.substring(first.length);
    }
    // Número pegado al movimiento: "10BMU" → "10 BMU".
    line = line.replaceFirst(RegExp(r'^(\d+)(?=[A-Za-z]{2})'), r'$1 ');
    // "db" leído como "dlb", "clb" o "d6".
    line = line.replaceAll(RegExp(r'\b(?:dlb|clb|d1b|d6|olb)\b', caseSensitive: false), 'db');
    // Prefijos pegados: "calrow", "dbsnatch", "kbswing".
    line = line.replaceAllMapped(
      RegExp(r'\b(cal|db|kb)(?=[a-z]{3,})', caseSensitive: false),
      (m) => '${m[1]} ',
    );
    return line;
  }

  /// Separa líneas que la lectura juntó: "WB 90 DU" → "WB" / "90 DU".
  static final _splitter = RegExp(
    r'(?<=[a-zA-Z])\s+(?=\d{1,3}\s*(?!m\b|km\b|cal|reps?\b|kg|lb|%)[a-zA-Z]{2})',
  );

  static DailyWorkout parse(String text, {required String fallbackName}) {
    final lines = text
        .split(RegExp(r'[\n\r]+'))
        .expand((l) => l.split(_splitter))
        .map(_clean)
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
      minutes = int.tryParse(_digits(am.group(1) ?? am.group(2) ?? ''));
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
    final candidates = <(DailyItem, bool)>[];
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
          reps = _reps(lr.group(1)!);
          move = lr.group(2)!;
        } else {
          final tr = _tailReps.firstMatch(line);
          if (tr != null && RegExp(r'[a-zA-Z]').hasMatch(tr.group(1)!)) {
            reps = _reps(tr.group(2)!);
            move = tr.group(1)!;
          }
        }
      }

      final known = matchMove(move);
      // Nombre del WOD: solo si es la primera línea de la pizarra, sin
      // números y no es un movimiento ("Fran", "Murph").
      if (raw == lines.first &&
          known == null &&
          reps.isEmpty &&
          !RegExp(r'\d').hasMatch(move) &&
          move.split(' ').length <= 3 &&
          !_norm(move).split(' ').every(_noise.contains)) {
        name = _title(move);
        continue;
      }
      // Logos, marcas y discos ("25 COMPETITION LB", "CROSSFIT").
      final words = _norm(move).split(' ').where((w) => w.isNotEmpty);
      if (known == null && (words.isEmpty || words.every(_noise.contains))) continue;
      if (known == null && reps.isEmpty) continue;
      if (known == null && !RegExp(r'[a-zA-Z]{2}').hasMatch(move)) continue;
      candidates.add((
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
        reps.isNotEmpty,
      ));
    }
    // Si la pizarra trae repeticiones, las líneas sin número son texto suelto
    // (logos, nombres) y se descartan.
    final anyReps = candidates.any((c) => c.$2);
    final items = [
      for (final c in candidates)
        if (c.$2 || !anyReps) c.$1,
    ];

    // Solo series × reps (fuerza): se registra por series.
    if (am == null && em == null && rounds == null && setsLines > 0 && setsLines == items.length) {
      format = WodFormat.sets;
    }

    return DailyWorkout(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      style: TrainingStyle.crossfit,
      name:
          name ?? (minutes != null && format == WodFormat.amrap ? 'AMRAP $minutes′' : fallbackName),
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

  /// "60cal" / "60 cal" → "60 cal"; "400m" → "400 m".
  static String _reps(String r) => r
      .replaceAll(' ', '')
      .replaceFirstMapped(
        RegExp(r'^([\d/\-]+)([a-zA-Z]+)$'),
        (m) => '${m[1]} ${m[2]!.toLowerCase()}',
      );

  static String _title(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}
