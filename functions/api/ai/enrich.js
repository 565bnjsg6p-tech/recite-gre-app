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
  const { request } = context;
  let payload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: { message: 'Invalid JSON body.' } }, 400);
  }

  const apiBaseUrl = String(payload.apiBaseUrl ?? '').trim();
  const apiKey = String(payload.apiKey ?? '').trim();
  const model = String(payload.model ?? '').trim();
  const messages = payload.messages;
  const responseFormat = payload.response_format;
  const temperature = payload.temperature;

  if (!apiBaseUrl) {
    return jsonResponse({ error: { message: 'Missing API base URL.' } }, 400);
  }
  if (!apiKey) {
    return jsonResponse({ error: { message: 'Missing API key.' } }, 400);
  }
  if (!model) {
    return jsonResponse({ error: { message: 'Missing model.' } }, 400);
  }

  const upstreamUrl = buildChatCompletionsUrl(apiBaseUrl);
  const upstream = await fetch(upstreamUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      messages,
      response_format: responseFormat,
      temperature,
    }),
  });

  const body = await upstream.text();
  return new Response(body, {
    status: upstream.status,
    headers: corsHeaders,
  });
}

function buildChatCompletionsUrl(baseUrl) {
  const trimmed = String(baseUrl ?? '').trim();
  const normalized = trimmed.endsWith('/') ? trimmed : `${trimmed}/`;
  const url = new URL(normalized);
  const path = url.pathname;
  if (path.endsWith('/v1/chat/completions') || path.endsWith('/chat/completions')) {
    return url.toString();
  }
  if (path.endsWith('/v1')) {
    return new URL('chat/completions', url).toString();
  }
  return new URL('v1/chat/completions', url).toString();
}

function jsonResponse(payload, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: corsHeaders,
  });
}
