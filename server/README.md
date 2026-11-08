# Servidor de Plate Calc (Vercel)

Una sola función: `POST /api/scan-board` recibe la foto de una pizarra y
devuelve el WOD leído por Gemini en JSON. La clave de Gemini vive solo aquí.

## Desplegar
1. vercel.com → Add New → Project → importar `datamull/plate_calc`.
2. **Root Directory**: `server`. Framework: Other. Deploy.
3. Settings → Environment Variables:
   - `GEMINI_API_KEY`: clave de https://aistudio.google.com/apikey
   - `APP_TOKEN`: el mismo texto secreto que va en Codemagic (`PLATECALC_AI_TOKEN`)
   - `GEMINI_MODEL` (opcional): por defecto `gemini-3.8-flash`
4. Redeploy para que tome las variables.

La dirección queda como `https://<proyecto>.vercel.app/api/scan-board`.

## Probar sin internet
`node test.mjs` (simula la respuesta de Gemini).
