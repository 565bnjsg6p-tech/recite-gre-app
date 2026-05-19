const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json; charset=utf-8',
};

export async function onRequestOptions() {
  return new Response(null, {
    status: 204,
    headers: corsHeaders,
  });
}

export async function onRequestPost(context) {
  const { request, env } = context;
  let payload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: { message: 'Invalid JSON body.' } }, 400);
  }

  const apiKey = String(payload.apiKey ?? env.OPENAI_API_KEY ?? '').trim();
  const model = String(payload.model ?? '').trim();
  const input = payload.input;
  const text = payload.text;

  if (!apiKey) {
    return jsonResponse({ error: { message: 'Missing OpenAI API key.' } }, 400);
  }
  if (!model) {
    return jsonResponse({ error: { message: 'Missing model.' } }, 400);
  }

  const upstream = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      input,
      text,
    }),
  });

  const body = await upstream.text();
  return new Response(body, {
    status: upstream.status,
    headers: corsHeaders,
  });
}

function jsonResponse(payload, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: corsHeaders,
  });
}
