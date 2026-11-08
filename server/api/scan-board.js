// Plate Calc · lee la foto de una pizarra de CrossFit con Gemini y devuelve
// el WOD en JSON. La clave de Gemini vive solo aquí (variable de entorno),
// nunca dentro de la app.
//
// Variables de entorno en Vercel:
//   GEMINI_API_KEY  clave de Google AI Studio (obligatoria)
//   APP_TOKEN       texto secreto que la app manda en "x-app-token" (obligatoria)
//   GEMINI_MODEL    modelo a usar (opcional, por defecto gemini-3.8-flash)

const MOVES = [
  'Wall Ball', 'Double Under', 'Single Under', 'Row', 'Bike', 'Ski', 'Run', 'Burpee',
  'Bar-Facing Burpee', 'Burpee Box Jump', 'Box Jump', 'Box Jump Over', 'Pull-Up',
  'Chest-to-Bar Pull-Up', 'Toes-to-Bar', 'Muscle-Up', 'Bar Muscle-Up', 'Handstand Push-Up',
  'Push-Up', 'Sit-Up', 'Air Squat', 'Lunge', 'Dumbbell Lunge', 'Dumbbell Snatch',
  'Dumbbell Thruster', 'Devil Press', 'Kettlebell Swing', 'Ring Dip', 'Rope Climb',
  'Thruster', 'Snatch', 'Power Snatch', 'Hang Power Snatch', 'Clean', 'Power Clean',
  'Hang Power Clean', 'Clean & Jerk', 'Jerk', 'Push Press', 'Shoulder-to-Overhead',
  'Overhead Press', 'Back Squat', 'Front Squat', 'Overhead Squat', 'Deadlift',
  'Sumo Deadlift High Pull', 'Bench Press',
];

const PROMPT = `You read photos of CrossFit / gym whiteboards (often handwritten, in English, Spanish or French).
Return ONLY the workout written on the board as JSON following the schema.

Rules:
- format: "amrap", "emom", "for_time" or "sets" (strength work like 5x5). If unclear, "for_time".
- minutes: AMRAP/EMOM duration or the time cap; null if not written.
- rounds: number of rounds for "N RFT / N rounds"; null otherwise.
- items: one entry per movement line, in order, top to bottom.
  - reps: as written ("21-15-9", "100", "400 m", "15/12 cal", "5x5"). Put calories as "80 cal", distances as "400 m".
  - movement: use one of these names when it matches (expand abbreviations like WB, DU, T2B, C2B, BMU, HSPU, KBS, db, cal row, echo bike):
    ${MOVES.join(', ')}.
    If none matches, write the movement in English, Title Case.
  - rx: weight or height as written, e.g. "20/14 lb", "24/16 kg", "24/20 in"; null if none.
  - percent: number if written as "@ 75%"; null otherwise.
- Ignore logos, brand names, gym names, plate labels, people's names, scores and anything that is not the workout.
- name: the workout's name if one is written (e.g. "Fran"); otherwise null.`;

const SCHEMA = {
  type: 'OBJECT',
  properties: {
    name: { type: 'STRING', nullable: true },
    format: { type: 'STRING', enum: ['amrap', 'emom', 'for_time', 'sets'] },
    minutes: { type: 'INTEGER', nullable: true },
    rounds: { type: 'INTEGER', nullable: true },
    items: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          reps: { type: 'STRING' },
          movement: { type: 'STRING' },
          rx: { type: 'STRING', nullable: true },
          percent: { type: 'NUMBER', nullable: true },
        },
        required: ['reps', 'movement'],
      },
    },
  },
  required: ['format', 'items'],
};

const MAX_IMAGE_CHARS = 4_000_000; // base64 (~3 MB); Vercel acepta hasta 4.5 MB

export const config = { maxDuration: 60 };

export default async function handler(req, res) {
  // Diagnóstico: GET /api/scan-board?ping=1 con el token prueba la clave.
  if (req.method === 'GET' && req.query?.ping) {
    if (req.headers['x-app-token'] !== process.env.APP_TOKEN) {
      return res.status(401).json({ error: 'unauthorized' });
    }
    const t0 = Date.now();
    const model = process.env.GEMINI_MODEL || 'gemini-3.8-flash';
    try {
      const r = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: 'POST',
          signal: AbortSignal.timeout(20000),
          headers: { 'Content-Type': 'application/json', 'x-goog-api-key': process.env.GEMINI_API_KEY || '' },
          body: JSON.stringify({ contents: [{ parts: [{ text: 'Reply with: ok' }] }] }),
        },
      );
      const data = await r.json();
      return res.status(200).json({
        model,
        hasKey: Boolean(process.env.GEMINI_API_KEY),
        status: r.status,
        ms: Date.now() - t0,
        reply: data?.candidates?.[0]?.content?.parts?.[0]?.text ?? null,
        error: data?.error?.message ?? null,
      });
    } catch (e) {
      return res.status(200).json({ model, ms: Date.now() - t0, error: String(e?.message || e) });
    }
  }
  if (req.method !== 'POST') return res.status(405).json({ error: 'method' });
  const token = process.env.APP_TOKEN;
  if (!token || req.headers['x-app-token'] !== token) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  const key = process.env.GEMINI_API_KEY;
  if (!key) return res.status(500).json({ error: 'missing GEMINI_API_KEY' });

  const body = typeof req.body === 'string' ? safeJson(req.body) : req.body;
  const image = body?.image;
  const mime = body?.mime || 'image/jpeg';
  if (typeof image !== 'string' || image.length < 100) {
    return res.status(400).json({ error: 'image' });
  }
  if (image.length > MAX_IMAGE_CHARS) return res.status(413).json({ error: 'too_large' });

  const model = process.env.GEMINI_MODEL || 'gemini-3.8-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
  try {
    const r = await fetch(url, {
      method: 'POST',
      signal: AbortSignal.timeout(45000),
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
      body: JSON.stringify({
        contents: [
          { parts: [{ text: PROMPT }, { inline_data: { mime_type: mime, data: image } }] },
        ],
        generationConfig: {
          temperature: 0,
          response_mime_type: 'application/json',
          response_schema: SCHEMA,
        },
      }),
    });
    const data = await r.json();
    if (!r.ok) {
      return res.status(502).json({ error: 'gemini', status: r.status, detail: data?.error?.message });
    }
    const text = data?.candidates?.[0]?.content?.parts?.map((p) => p.text || '').join('') || '';
    const wod = safeJson(text);
    if (!wod || !Array.isArray(wod.items)) return res.status(502).json({ error: 'bad_output' });
    return res.status(200).json(clean(wod));
  } catch (e) {
    return res.status(502).json({ error: 'network', detail: String(e?.message || e) });
  }
}

function safeJson(s) {
  try {
    return JSON.parse(s);
  } catch {
    return null;
  }
}

/** Deja solo los campos esperados, con tipos correctos. */
export function clean(w) {
  const int = (v) => (Number.isFinite(Number(v)) && Number(v) > 0 ? Math.round(Number(v)) : null);
  const str = (v) => (typeof v === 'string' && v.trim() ? v.trim().slice(0, 80) : null);
  const formats = ['amrap', 'emom', 'for_time', 'sets'];
  return {
    name: str(w.name),
    format: formats.includes(w.format) ? w.format : 'for_time',
    minutes: int(w.minutes),
    rounds: int(w.rounds),
    items: (w.items || [])
      .filter((i) => str(i?.movement))
      .slice(0, 30)
      .map((i) => ({
        reps: str(i.reps) || '',
        movement: str(i.movement),
        rx: str(i.rx),
        percent: Number.isFinite(Number(i.percent)) && i.percent !== null ? Number(i.percent) : null,
      })),
  };
}
