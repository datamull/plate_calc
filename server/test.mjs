// Prueba local sin internet: simula Gemini y verifica la función.
import handler from './api/scan-board.js';

process.env.APP_TOKEN = 't';
process.env.GEMINI_API_KEY = 'k';
let sent;
globalThis.fetch = async (url, opts) => {
  sent = { url, body: JSON.parse(opts.body), headers: opts.headers };
  const out = { name: null, format: 'amrap', minutes: 32, rounds: null,
    items: [{ reps: '100', movement: 'Wall Ball', rx: '20/14 lb', percent: null },
            { reps: '80 cal', movement: 'Row', rx: null, percent: null }] };
  return { ok: true, status: 200, json: async () => ({ candidates: [{ content: { parts: [{ text: JSON.stringify(out) }] } }] }) };
};
const res = () => { const r = { code: 0, out: null }; r.status = (c) => { r.code = c; return r; }; r.json = (o) => { r.out = o; return r; }; return r; };

let r = res(); await handler({ method: 'POST', headers: {}, body: {} }, r);
console.assert(r.code === 401, 'sin token → 401');
r = res(); await handler({ method: 'POST', headers: { 'x-app-token': 't' }, body: { image: 'x'.repeat(200) } }, r);
console.assert(r.code === 200 && r.out.minutes === 32 && r.out.items.length === 2, 'ok');
console.assert(sent.url.includes(':generateContent') && sent.headers['x-goog-api-key'] === 'k', 'llamada a Gemini');
console.assert(sent.body.contents[0].parts[1].inline_data.data.length === 200, 'imagen enviada');
console.log(r.code, JSON.stringify(r.out));
