import http from 'node:http';
import { pathToFileURL } from 'node:url';

import { handleEventsRoute } from './events.mjs';

const iamTokenUrl = 'https://iam.cloud.ibm.com/identity/token';
let cachedIamToken;
let cachedIamTokenExpiry = 0;
const searchCache = new Map();
const inFlightSearches = new Map();
const configuredCacheTtl = Number(process.env.SEARCH_CACHE_TTL_MS || 300_000);
const searchCacheTtlMs = Number.isFinite(configuredCacheTtl)
  ? Math.max(0, configuredCacheTtl)
  : 300_000;

function requireSetting(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new ConfigurationError(`${name} 설정이 필요합니다.`);
  return value;
}

class ConfigurationError extends Error {}

// Search and 통계 feedback share one watsonx model/project from .env.
export function resolveWatsonxChatTarget(env = process.env) {
  return {
    modelId: env.WATSONX_MODEL_ID?.trim() || '',
    projectId: env.WATSONX_PROJECT_ID?.trim() || '',
  };
}

function sendJson(response, statusCode, data) {
  response.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'Access-Control-Allow-Origin': process.env.ALLOWED_ORIGIN || '*',
  });
  response.end(JSON.stringify(data));
}

async function getIamToken() {
  if (cachedIamToken && Date.now() < cachedIamTokenExpiry - 60_000) {
    return cachedIamToken;
  }

  const body = new URLSearchParams({
    grant_type: 'urn:ibm:params:oauth:grant-type:apikey',
    apikey: requireSetting('WATSONX_API_KEY'),
  });
  const response = await fetch(iamTokenUrl, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body,
  });
  const data = await response.json();
  if (!response.ok || typeof data.access_token !== 'string') {
    throw new Error('IBM Cloud IAM 인증에 실패했습니다.');
  }
  cachedIamToken = data.access_token;
  cachedIamTokenExpiry = Number(data.expiration || 0) * 1000;
  return cachedIamToken;
}

export function normalizeIntent(value, fallbackQuery) {
  const searchQuery = typeof value?.searchQuery === 'string'
    ? value.searchQuery.trim().slice(0, 120)
    : '';
  const parsedMaxPrice = Number(value?.maxPrice);
  return {
    searchQuery: searchQuery || fallbackQuery,
    maxPrice: Number.isFinite(parsedMaxPrice) && parsedMaxPrice > 0
      ? Math.round(parsedMaxPrice)
      : null,
  };
}

export function shouldInterpretQuery(query) {
  return /(?:예산|이하|미만|이내|최대|가격대|[\d,]+\s*(?:천|만)?\s*원)/.test(
    query,
  );
}

// Send a system prompt we wrote in code plus a user message.
// Always uses WATSONX_MODEL_ID / WATSONX_PROJECT_ID. Returns parsed JSON.
async function callAiWithPrompt({
  system,
  user,
  maxTokens,
  temperature = 0,
}) {
  const target = resolveWatsonxChatTarget();
  if (!target.modelId || !target.projectId) {
    throw new ConfigurationError(
      'WATSONX_MODEL_ID / WATSONX_PROJECT_ID 설정이 필요합니다.',
    );
  }

  const token = await getIamToken();
  const baseUrl = requireSetting('WATSONX_URL').replace(/\/+$/, '');
  const version = process.env.WATSONX_API_VERSION || '2023-10-25';
  const response = await fetch(
    `${baseUrl}/ml/v1/text/chat?version=${encodeURIComponent(version)}`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model_id: target.modelId,
        project_id: target.projectId,
        response_format: { type: 'json_object' },
        temperature,
        max_tokens: maxTokens,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user },
        ],
      }),
      signal: AbortSignal.timeout(25_000),
    },
  );
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data?.errors?.[0]?.message || 'watsonx AI 요청에 실패했습니다.');
  }
  const content = data?.choices?.[0]?.message?.content;
  if (typeof content !== 'string') {
    throw new Error('watsonx AI 응답을 읽을 수 없습니다.');
  }
  try {
    return JSON.parse(content);
  } catch {
    throw new Error('watsonx AI 응답을 읽을 수 없습니다.');
  }
}

const searchSystemPrompt =
  '당신은 한국 온라인 쇼핑 검색어 분석기입니다. 실제 상품이나 가격을 만들지 마세요. 사용자 문장에서 핵심 상품 검색어와 명시된 최대 예산만 추출하고 JSON 객체 {"searchQuery": string, "maxPrice": number|null}만 반환하세요.';

async function interpretQuery(query) {
  const parsed = await callAiWithPrompt({
    system: searchSystemPrompt,
    user: query,
    maxTokens: 120,
  });
  return normalizeIntent(parsed, query);
}

export function normalizeShoppingResults(data, maxPrice = null) {
  const rawItems = Array.isArray(data?.shopping_results)
    ? data.shopping_results
    : [];
  const items = [];
  for (const [index, item] of rawItems.entries()) {
    const price = Math.round(Number(item?.extracted_price));
    const name = typeof item?.title === 'string' ? item.title.trim() : '';
    const imageUrl = item?.thumbnail || item?.serpapi_thumbnail || '';
    if (!name || !Number.isFinite(price) || price < 1 || !imageUrl) continue;
    if (maxPrice && price > maxPrice) continue;
    items.push({
      id: String(item.product_id || `${index + 1}-${name.slice(0, 32)}`),
      name,
      price,
      imageUrl: String(imageUrl),
      productUrl: String(item.product_link || item.link || ''),
      source: String(item.source || 'Google Shopping'),
    });
    if (items.length === 12) break;
  }
  return items;
}

async function searchShopping(intent) {
  const url = new URL('https://serpapi.com/search.json');
  url.search = new URLSearchParams({
    engine: 'google_shopping',
    q: intent.searchQuery,
    gl: 'kr',
    hl: 'ko',
    location: 'Seoul, South Korea',
    api_key: requireSetting('SERPAPI_API_KEY'),
  });
  const response = await fetch(url, { headers: { Accept: 'application/json' } });
  const data = await response.json();
  if (!response.ok || data?.error) {
    throw new Error(data?.error || '상품 검색 제공자 요청에 실패했습니다.');
  }
  return normalizeShoppingResults(data, intent.maxPrice);
}

// Keep only well-formed cards and cap at 3 so the UI stays small.
export function normalizeInsights(value) {
  const rawInsights = Array.isArray(value?.insights) ? value.insights : [];
  const insights = [];
  for (const [index, item] of rawInsights.entries()) {
    const title = typeof item?.title === 'string' ? item.title.trim() : '';
    const body = typeof item?.body === 'string' ? item.body.trim() : '';
    if (!title || !body) continue;
    const actionCategory =
      typeof item?.actionCategory === 'string' ? item.actionCategory.trim() : '';
    const actionLabel =
      typeof item?.actionLabel === 'string' && item.actionLabel.trim()
        ? item.actionLabel.trim()
        : actionCategory
          ? `${actionCategory} 내역 확인하기`
          : '목표 다시 보기';
    insights.push({
      id: typeof item?.id === 'string' && item.id.trim()
        ? item.id.trim()
        : `insight-${index + 1}`,
      title: title.slice(0, 60),
      body: body.slice(0, 300),
      actionLabel: actionLabel.slice(0, 40),
      actionCategory,
    });
    if (insights.length === 3) break;
  }
  return insights;
}

const insightSystemPrompt =
  '당신은 한국어 개인 금융 코치입니다. 사용자의 월간 소비 요약(JSON)을 읽고 ' +
  '실천 가능한 피드백 카드를 1~3개 만드세요. 존댓말의 짧고 친근한 문장을 쓰고, ' +
  '요약에 없는 금액이나 거래를 지어내지 마세요. actionCategory는 요약에 등장한 ' +
  '카테고리 이름 그대로 쓰거나 빈 문자열로 두세요. JSON 객체 {"insights": ' +
  '[{"id": string, "title": string, "body": string, "actionLabel": string, ' +
  '"actionCategory": string}]}만 반환하세요.';

async function generateSpendingInsights(summary) {
  const parsed = await callAiWithPrompt({
    system: insightSystemPrompt,
    user: JSON.stringify(summary),
    maxTokens: 700,
    temperature: 0.2,
  });
  return normalizeInsights(parsed);
}

async function readJsonBody(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
    if (Buffer.concat(chunks).length > 64_000) {
      throw new Error('요청 본문이 너무 큽니다.');
    }
  }
  if (chunks.length === 0) return null;
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null;
  }
}

async function searchProducts(query) {
  const cacheKey = query.trim().toLocaleLowerCase('ko-KR');
  const cached = searchCache.get(cacheKey);
  if (cached && Date.now() - cached.savedAt < searchCacheTtlMs) {
    return cached.value;
  }

  const inFlight = inFlightSearches.get(cacheKey);
  if (inFlight) return inFlight;

  const search = (async () => {
    const intent = shouldInterpretQuery(query)
      ? await interpretQuery(query)
      : normalizeIntent(null, query);
    const items = await searchShopping(intent);
    const value = { query: intent.searchQuery, items };

    if (searchCache.size >= 100) {
      searchCache.delete(searchCache.keys().next().value);
    }
    searchCache.set(cacheKey, { savedAt: Date.now(), value });
    return value;
  })();

  inFlightSearches.set(cacheKey, search);
  try {
    return await search;
  } finally {
    inFlightSearches.delete(cacheKey);
  }
}

async function handleRequest(request, response) {
  if (request.method === 'OPTIONS') {
    response.writeHead(204, {
      'Access-Control-Allow-Origin': process.env.ALLOWED_ORIGIN || '*',
      'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    });
    response.end();
    return;
  }

  const url = new URL(request.url, `http://${request.headers.host || 'localhost'}`);
  if (request.method === 'GET' && url.pathname === '/health') {
    sendJson(response, 200, {
      ok: true,
      configured: {
        watsonx:
          Boolean(process.env.WATSONX_API_KEY) &&
          Boolean(process.env.WATSONX_PROJECT_ID) &&
          Boolean(process.env.WATSONX_URL) &&
          Boolean(process.env.WATSONX_MODEL_ID),
        spendingInsights:
          Boolean(process.env.WATSONX_API_KEY) &&
          Boolean(process.env.WATSONX_PROJECT_ID) &&
          Boolean(process.env.WATSONX_URL) &&
          Boolean(process.env.WATSONX_MODEL_ID),
        productSearch: Boolean(process.env.SERPAPI_API_KEY),
      },
    });
    return;
  }

  // 이벤트 탭 라우트 먼저 시도 (처리했으면 여기서 종료)
  if (url.pathname.startsWith('/api/events')) {
    const handled = await handleEventsRoute(request, response, url);
    if (handled) return;
  }

  if (request.method === 'POST' && url.pathname === '/api/insights') {
    const summary = await readJsonBody(request).catch(() => null);
    if (!summary || typeof summary !== 'object' || Array.isArray(summary)) {
      sendJson(response, 400, { error: '소비 요약(JSON)이 필요합니다.' });
      return;
    }
    try {
      const insights = await generateSpendingInsights(summary);
      sendJson(response, 200, { insights });
    } catch (error) {
      const statusCode = error instanceof ConfigurationError ? 503 : 502;
      sendJson(response, statusCode, {
        error:
          error instanceof Error ? error.message : 'AI 피드백 생성에 실패했습니다.',
      });
    }
    return;
  }

  if (request.method !== 'GET' || url.pathname !== '/api/products/search') {
    sendJson(response, 404, { error: '요청한 API를 찾을 수 없습니다.' });
    return;
  }

  const query = (url.searchParams.get('q') || '').trim();
  if (query.length < 2 || query.length > 120) {
    sendJson(response, 400, { error: '검색어를 2~120자로 입력해 주세요.' });
    return;
  }

  try {
    const result = await searchProducts(query);
    sendJson(response, 200, result);
  } catch (error) {
    const statusCode = error instanceof ConfigurationError ? 503 : 502;
    sendJson(response, statusCode, {
      error: error instanceof Error ? error.message : '상품 검색에 실패했습니다.',
    });
  }
}

export function startServer(port = Number(process.env.PORT || 8080)) {
  const server = http.createServer(handleRequest);
  server.listen(port, '0.0.0.0', () => {
    console.log(`Product search server listening on http://0.0.0.0:${port}`);
  });
  return server;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  startServer();
}
