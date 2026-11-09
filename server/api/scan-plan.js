// Plate Calc · lee el PDF de la planificación semanal (el que manda el coach
// o el box) con Gemini y devuelve la semana ordenada por día: cada día con
// sus bloques (fuerza, WOD, accesorios…) en el mismo formato que la pizarra.
//
// Usa las mismas variables de entorno que scan-board.js.

import { MOVES, clean, safeJson } from './scan-board.js';

const PROMPT = `You read a weekly training plan (PDF from a CrossFit box, weightlifting coach or gym; English, Spanish or French).
Return the whole week as JSON following the schema.

Rules:
- days: one entry per training day found, in order. day is the weekday: "mon","tue","wed","thu","fri","sat","sun".
  Map names like Lunes/Lundi/Monday, "Día 1" (= mon), "Day 2" (= tue)… If days are numbered without weekdays, start at mon.
  Skip rest days.
- blocks: each separate part of that day, in order (e.g. "Strength", "Skill", "WOD", "Metcon", "Accessory", "Conditioning").
  - title: the block's heading as written (short), or null.
  - style: "haltero" for olympic lifting / strength work with percentages, "gym" for bodybuilding / hypertrophy,
    otherwise "crossfit".
  - name: the workout's name if written (e.g. "Fran", "Murph"); otherwise null.
  - format: "amrap", "emom", "for_time" or "sets" (strength like 5x5, 5-3-1, sets x reps). If unclear: "sets" for strength, "for_time" otherwise.
  - minutes: AMRAP/EMOM duration or time cap; null if not written.
  - rounds: number of rounds for "N RFT / N rounds"; null otherwise.
  - items: one entry per movement line, in order.
    - reps: as written ("21-15-9", "100", "400 m", "15/12 cal", "5x5", "5-5-3-3-1").
    - movement: use one of these names when it matches (expand abbreviations like WB, DU, T2B, C2B, BMU, HSPU, KBS, db, cal row, echo bike):
      ${MOVES.join(', ')}.
      If none matches, write the movement in English, Title Case.
    - rx: weight or height as written ("20/14 lb", "24/16 kg"); null if none.
    - percent: number if written as "@ 75%" (use the main/top percentage); null otherwise.
  - notes: one short line with important instructions (tempo, rest, scaling) or null.
- week_start: the Monday of that week as YYYY-MM-DD if a date is written; otherwise null.
- title: the plan's title if written (e.g. "Semana 3 · Fuerza"); otherwise null.
- Ignore logos, contact info, prices, sponsors and anything that is not training.

Layout and notation commonly used by boxes (follow these):
- A day page can have columns side by side (e.g. "FORCE / TECHNIQUE" on the left, "WOD / METCON" on the right) and more
  sections below ("RENFORCEMENT", "Accessory"). Each column/section is its own block, in reading order: left column,
  right column, then the sections below.
- Skip sections that are not a real workout: "Échauffement / Warm-up" when it only says "au choix coach" or similar,
  and placeholders like "XXXX", "À compléter", "TBD", "-". A day with only placeholders is skipped.
- "a|b|c" between movements means scaling options (RX first): use the FIRST as movement and mention the others in notes
  ("Options: C2B, Pull-Up"). "16|12 Cal" means men|women: reps "16/12 cal".
- Weight groups like "(24|20) (50|35) (35|25)" are levels RX / intermediate / scaled, each men|women.
  rx = the first group written with "/" and the unit if known ("24/20 in", "50/35 lb"; lb if no unit and the values look
  like pounds). Put the other levels in notes ("Inter 35/25 lb, Scaled 25/15").
- "Emom 12" followed by numbered lines "1- …", "2- …": format "emom", minutes 12, one item per numbered line
  (drop the "1-" prefix). "*80%*" or "@80%" is percent 80. Text in asterisks that is not a percentage
  (tempo, pauses like "*3 sec Pause*") goes to notes.
- "3X" / "3 rounds" over a list of accessories: format "sets", rounds 3; "rest 1:00min" goes to notes.
- "Every 2:00 x5": format "emom", minutes 10, notes "Every 2:00 x5".
- "1 min on, 1 min off 3x" and similar intervals: format "for_time", notes with the interval scheme.
- "Max …" reps: reps "Max".
- Two workouts in the same column (e.g. "Emom 12 (UPPER)" then "Emom 12 (GLUTES)") are separate blocks; put the part in
  parentheses in the title ("FORCE / TECHNIQUE · UPPER").
- Keep the implement: "db hang snatch" is "Dumbbell Hang Snatch" (never a barbell lift), "kb swing" is "Kettlebell Swing".
- "Squat Snatch" / "Squat Clean" stay as written.
- "8|8" or "6/6" with the same number twice means per side: reps "8/8".
- Only use a name from the list when it is really the same movement. "2db step over box" is "Dumbbell Box Step-Over",
  not a lunge; "Side plank on the ring" stays as is. Keep the movement's own name (in English) when unsure.
- Units: box and jump heights are inches ("24/20 in"); wall balls, dumbbells, kettlebells and barbells are pounds
  ("30/20 lb") unless "kg" is written.
- Day headers can carry a theme ("CROSSFIT", "HYROX", "TEAM WOD"): use it to choose style (all of these are "crossfit")
  and you may mention it in notes of the first block.
- Plan title: the document heading (e.g. "IMPULSION / PROGRAMMATION HEBDOMADAIRE").`;

const ITEM = {
  type: 'OBJECT',
  properties: {
    reps: { type: 'STRING' },
    movement: { type: 'STRING' },
    rx: { type: 'STRING', nullable: true },
    percent: { type: 'NUMBER', nullable: true },
  },
  required: ['reps', 'movement'],
};

const SCHEMA = {
  type: 'OBJECT',
  properties: {
    title: { type: 'STRING', nullable: true },
    week_start: { type: 'STRING', nullable: true },
    days: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          day: { type: 'STRING', enum: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'] },
          blocks: {
            type: 'ARRAY',
            items: {
              type: 'OBJECT',
              properties: {
                title: { type: 'STRING', nullable: true },
                style: { type: 'STRING', enum: ['crossfit', 'haltero', 'gym'] },
                name: { type: 'STRING', nullable: true },
                format: { type: 'STRING', enum: ['amrap', 'emom', 'for_time', 'sets'] },
                minutes: { type: 'INTEGER', nullable: true },
                rounds: { type: 'INTEGER', nullable: true },
                notes: { type: 'STRING', nullable: true },
                items: { type: 'ARRAY', items: ITEM },
              },
              required: ['format', 'items'],
            },
          },
        },
        required: ['day', 'blocks'],
      },
    },
  },
  required: ['days'],
};

// base64 de ~3 MB de PDF; Vercel acepta hasta 4.5 MB por petición.
const MAX_PDF_CHARS = 4_200_000;
const DAYS = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

export const config = { maxDuration: 60 };

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'method' });
  const token = process.env.APP_TOKEN;
  if (!token || req.headers['x-app-token'] !== token) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  const key = process.env.GEMINI_API_KEY;
  if (!key) return res.status(500).json({ error: 'missing GEMINI_API_KEY' });

  const body = typeof req.body === 'string' ? safeJson(req.body) : req.body;
  const pdf = body?.pdf;
  if (typeof pdf !== 'string' || pdf.length < 100) return res.status(400).json({ error: 'pdf' });
  if (pdf.length > MAX_PDF_CHARS) return res.status(413).json({ error: 'too_large' });

  // ?model= solo para pruebas (la ruta ya exige el token).
  const forced = String(req.query?.model || '').replace(/[^a-z0-9.\-]/gi, '');
  const models = forced
    ? [forced]
    : [
        // 3.5 Flash lee PDFs de box con precisión y en ~15 s; el liviano es
        // el respaldo si está ocupado.
        process.env.PLAN_MODEL || 'gemini-3.5-flash',
        process.env.GEMINI_FALLBACK_MODEL || 'gemini-3.5-flash-lite',
      ];
  const deadline = Date.now() + 55000;
  let last = { status: 0, detail: '' };
  for (const model of models) {
    const left = deadline - Date.now();
    if (left < 6000) break;
    // El principal tiene 38 s; si no alcanza, el liviano responde rápido.
    const isLast = model === models[models.length - 1];
    const out = await callPlan(model, key, pdf, Math.min(left, isLast ? 50000 : 38000));
    if (out.plan) return res.status(200).json({ ...cleanPlan(out.plan), model });
    last = { status: out.status, detail: out.detail, model };
    console.error('gemini plan fallo', model, out.status, out.detail);
    if (out.status >= 400 && out.status < 500 && out.status !== 429) break;
  }
  return res.status(502).json({ error: 'gemini', ...last });
}

async function callPlan(model, key, pdf, timeoutMs) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
  try {
    const r = await fetch(url, {
      method: 'POST',
      signal: AbortSignal.timeout(timeoutMs),
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
      body: JSON.stringify({
        contents: [
          { parts: [{ text: PROMPT }, { inline_data: { mime_type: 'application/pdf', data: pdf } }] },
        ],
        generationConfig: {
          temperature: 0,
          response_mime_type: 'application/json',
          response_schema: SCHEMA,
          // Leer un PDF ordenado no necesita razonamiento largo: más rápido.
          thinkingConfig: { thinkingLevel: 'low' },
        },
      }),
    });
    const data = await r.json().catch(() => null);
    if (!r.ok) return { status: r.status, detail: data?.error?.message || '' };
    const text = data?.candidates?.[0]?.content?.parts?.map((p) => p.text || '').join('') || '';
    const plan = safeJson(text);
    if (!plan || !Array.isArray(plan.days) || plan.days.length === 0) {
      return { status: 200, detail: 'empty' };
    }
    return { plan };
  } catch (e) {
    return { status: 0, detail: String(e?.message || e) };
  }
}

/** Deja solo los campos esperados; un día por día de la semana, en orden. */
export function cleanPlan(p) {
  const str = (v, n = 80) => (typeof v === 'string' && v.trim() ? v.trim().slice(0, n) : null);
  const styles = ['crossfit', 'haltero', 'gym'];
  const byDay = new Map();
  for (const d of p.days || []) {
    if (!DAYS.includes(d?.day)) continue;
    const blocks = (d.blocks || [])
      .map((b) => ({
        ...clean(b),
        title: str(b?.title, 40),
        style: styles.includes(b?.style) ? b.style : 'crossfit',
        notes: str(b?.notes, 160),
      }))
      .filter((b) => b.items.length > 0)
      .slice(0, 8);
    if (blocks.length === 0) continue;
    byDay.set(d.day, [...(byDay.get(d.day) || []), ...blocks]);
  }
  const ws = str(p.week_start, 10);
  return {
    title: str(p.title, 60),
    week_start: ws && /^\d{4}-\d{2}-\d{2}$/.test(ws) ? ws : null,
    days: DAYS.filter((d) => byDay.has(d)).map((d) => ({ day: d, blocks: byDay.get(d) })),
  };
}
