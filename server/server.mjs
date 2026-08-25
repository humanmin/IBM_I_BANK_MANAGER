import http from 'node:http';
import { pathToFileURL } from 'node:url';

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

async function interpretQuery(query) {
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
        model_id: requireSetting('WATSONX_MODEL_ID'),
        project_id: requireSetting('WATSONX_PROJECT_ID'),
        response_format: { type: 'json_object' },
        temperature: 0,
        max_tokens: 120,
        messages: [
          {
            role: 'system',
            content:
              '당신은 한국 온라인 쇼핑 검색어 분석기입니다. 실제 상품이나 가격을 만들지 마세요. 사용자 문장에서 핵심 상품 검색어와 명시된 최대 예산만 추출하고 JSON 객체 {"searchQuery": string, "maxPrice": number|null}만 반환하세요.',
          },
          { role: 'user', content: query },
        ],
      }),
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
  return normalizeIntent(JSON.parse(content), query);
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
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
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
        productSearch: Boolean(process.env.SERPAPI_API_KEY),
      },
    });
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
