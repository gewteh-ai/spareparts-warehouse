// Secure serverless function: receives a part photo, asks Google Gemini to
// read it, and returns structured fields as JSON. The API key stays here on
// the server (Netlify env var GEMINI_API_KEY) and is never exposed to the app.

const FALLBACK_MODELS = [
  'gemini-flash-latest', 'gemini-2.5-flash-lite', 'gemini-2.0-flash',
  'gemini-2.5-flash', 'gemini-flash-lite-latest', 'gemini-pro-latest'
];

const json = (obj, status = 200) =>
  new Response(JSON.stringify(obj), { status, headers: { 'Content-Type': 'application/json' } });

async function discoverModels(key) {
  try {
    const r = await fetch('https://generativelanguage.googleapis.com/v1beta/models?key=' + key + '&pageSize=200');
    const d = await r.json();
    if (!r.ok || !Array.isArray(d.models)) return [];
    const usable = d.models
      .filter(m => (m.supportedGenerationMethods || []).includes('generateContent'))
      .map(m => (m.name || '').replace(/^models\//, ''))
      .filter(Boolean);
    const rank = (n) => {
      n = n.toLowerCase();
      if (/embedding|aqa|imagen|tts|vision-only/.test(n)) return 9;
      if (n.includes('flash-lite')) return 0;
      if (n.includes('flash')) return 1;
      if (n.includes('pro')) return 3;
      return 2;
    };
    return usable.sort((a, b) => rank(a) - rank(b));
  } catch (e) { return []; }
}

export default async (req) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  const key = process.env.GEMINI_API_KEY;
  if (!key) return json({ error: 'AI not configured yet (GEMINI_API_KEY is missing in Netlify).' }, 500);

  let body;
  try { body = await req.json(); } catch { return json({ error: 'Bad request' }, 400); }
  const image = body.image;
  const mime = body.mime || 'image/jpeg';
  if (!image) return json({ error: 'No image provided' }, 400);

  const prompt =
    'You are cataloguing automotive car spare parts for a shop in Malaysia. ' +
    'Look at this photo of a spare part or its packaging/box and extract what you can. ' +
    'Respond ONLY as JSON with these exact fields: ' +
    'name (the type of part, e.g. "Brake Pad", "Tie Rod End"), ' +
    'brand (manufacturer/brand if printed), ' +
    'part_number (the printed part number / SKU if clearly visible), ' +
    'oem (OEM or cross-reference number if printed), ' +
    'category (one of: Brakes, Steering, Electrical, Engine, Suspension, Transmission, Body, Filters, Cooling, Other), ' +
    'dimensions (any size/spec printed on it, else ""), ' +
    'engine_specific (true only if it is an engine/electrical part whose fit depends on the engine code, else false), ' +
    'fitments (ONLY if the packaging explicitly prints compatible vehicles/applications: an array of objects each with ' +
    'make, model, year_from (number or ""), year_to (number or ""), engine (code if shown, else ""); ' +
    'use an empty array [] if no vehicles are printed — do NOT guess vehicle compatibility). ' +
    'Use an empty string "" for anything not visible. Never guess a part number, OEM, or vehicle you cannot read.';

  const payload = {
    contents: [{ parts: [ { text: prompt }, { inline_data: { mime_type: mime, data: image } } ] }],
    generationConfig: { responseMimeType: 'application/json', temperature: 0.1 }
  };

  const discovered = await discoverModels(key);
  const seen = {};
  const modelsToTry = discovered.concat(FALLBACK_MODELS).filter(m => (m && !seen[m] && (seen[m] = 1)));

  let lastErr = 'no usable model found';
  for (const model of modelsToTry) {
    let resp;
    try {
      resp = await fetch(
        'https://generativelanguage.googleapis.com/v1beta/models/' + model + ':generateContent?key=' + key,
        { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) }
      );
    } catch (e) { lastErr = 'Could not reach the AI service.'; continue; }

    const data = await resp.json().catch(() => ({}));
    if (resp.ok) {
      const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
      let result; try { result = JSON.parse(text); } catch { result = {}; }
      return json({ result, model });
    }

    lastErr = data?.error?.message || ('HTTP ' + resp.status);
    const hardStop = /quota|rate limit|resource has been exhausted|api key|permission|unauthenticated|unauthorized|billing/i.test(lastErr);
    if (hardStop) return json({ error: lastErr }, 502);
  }

  return json({ error: 'No usable Gemini model for your account. Last error: ' + lastErr }, 502);
};
