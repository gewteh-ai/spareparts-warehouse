// Vercel serverless function: receives a part photo, asks Google Gemini to
// read it, returns structured fields as JSON. Key stays server-side (Vercel
// env var GEMINI_API_KEY) and is never exposed to the app.
// (CommonJS so it works without a package.json "type":"module".)

const MODELS = ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-flash-latest', 'gemini-2.5-flash-lite'];

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const key = process.env.GEMINI_API_KEY;
  if (!key) return res.status(500).json({ error: 'AI not configured yet (GEMINI_API_KEY missing in Vercel).' });

  const body = req.body || {};
  const image = body.image;
  const mime = body.mime || 'image/jpeg';
  if (!image) return res.status(400).json({ error: 'No image provided' });

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

  let lastErr = 'no model available';
  for (const model of MODELS) {
    let resp;
    try {
      resp = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${key}`,
        { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) }
      );
    } catch (e) { lastErr = 'Could not reach the AI service.'; continue; }

    const data = await resp.json().catch(() => ({}));
    if (resp.ok) {
      const text = (data && data.candidates && data.candidates[0] && data.candidates[0].content
        && data.candidates[0].content.parts && data.candidates[0].content.parts[0]
        && data.candidates[0].content.parts[0].text) || '{}';
      let result; try { result = JSON.parse(text); } catch (e) { result = {}; }
      return res.status(200).json({ result, model });
    }

    lastErr = (data && data.error && data.error.message) || ('HTTP ' + resp.status);
    const modelIssue = /not found|not available|not supported|unsupported|does not exist|deprecat/i.test(lastErr);
    if (!modelIssue) return res.status(502).json({ error: lastErr });
  }

  return res.status(502).json({ error: 'No available Gemini model right now. Last error: ' + lastErr });
};
