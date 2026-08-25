import crypto from 'node:crypto';
import { getFirestore } from 'firebase-admin/firestore';

import { verifyRequestAuth } from './auth-middleware.mjs';
import { encryptToken, decryptToken } from './token-crypto.mjs';
import {
  buildAuthorizeUrl,
  exchangeCodeForToken,
  fetchAccountList,
  fetchBalance,
  revokeConsent,
} from './openbanking-client.mjs';

function requireSetting(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`${name} 설정이 필요합니다.`);
  return value;
}

function sendJson(response, statusCode, data) {
  response.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'Access-Control-Allow-Origin': process.env.ALLOWED_ORIGIN || '*',
  });
  response.end(JSON.stringify(data));
}

function maskAccountNumber(raw) {
  // 예: 123456789012 -> 123-**-*****012 (은행마다 자릿수 다르므로 단순 마스킹)
  if (raw.length <= 6) return raw;
  const head = raw.slice(0, 3);
  const tail = raw.slice(-3);
  return `${head}-${'*'.repeat(raw.length - 6)}-${tail}`;
}

// 오픈뱅킹 콜백은 state 파라미터만으로 uid를 복원해야 하므로,
// link/start 시점에 state -> uid 매핑을 잠깐 저장해둡니다 (TTL 짧게).
const pendingStates = new Map();

async function handleLinkStart(request, response) {
  const auth = await verifyRequestAuth(request);
  if (!auth) return sendJson(response, 401, { error: '로그인이 필요해요.' });

  const state = crypto.randomBytes(16).toString('hex');
  pendingStates.set(state, { uid: auth.uid, createdAt: Date.now() });

  try {
    sendJson(response, 200, { url: buildAuthorizeUrl(state) });
  } catch (error) {
    sendJson(response, 503, { error: error.message });
  }
}

async function handleLinkCallback(url, response) {
  const code = url.searchParams.get('code');
  const state = url.searchParams.get('state');
  const pending = state && pendingStates.get(state);

  if (!code || !pending) {
    sendJson(response, 400, { error: '유효하지 않은 콜백 요청입니다.' });
    return;
  }
  pendingStates.delete(state);

  try {
    const { accessToken, refreshToken, userSeqNo } = await exchangeCodeForToken(code);
    const encryptionKey = requireSetting('TOKEN_ENCRYPTION_KEY');

    const db = getFirestore();
    await db
      .collection('users')
      .doc(pending.uid)
      .collection('bankLink')
      .doc('openbanking')
      .set({
        userSeqNo,
        accessTokenEnc: encryptToken(accessToken, encryptionKey),
        refreshTokenEnc: encryptToken(refreshToken, encryptionKey),
        linkedAt: new Date().toISOString(),
      });

    sendJson(response, 200, { linked: true });
  } catch (error) {
    sendJson(response, 502, { error: error.message });
  }
}

async function loadLink(uid) {
  const db = getFirestore();
  const doc = await db
    .collection('users')
    .doc(uid)
    .collection('bankLink')
    .doc('openbanking')
    .get();
  if (!doc.exists) return null;

  const data = doc.data();
  const encryptionKey = requireSetting('TOKEN_ENCRYPTION_KEY');
  return {
    userSeqNo: data.userSeqNo,
    accessToken: decryptToken(data.accessTokenEnc, encryptionKey),
    refreshToken: decryptToken(data.refreshTokenEnc, encryptionKey),
  };
}

async function handleListAccounts(request, response) {
  const auth = await verifyRequestAuth(request);
  if (!auth) return sendJson(response, 401, { error: '로그인이 필요해요.' });

  try {
    const link = await loadLink(auth.uid);
    if (!link) return sendJson(response, 200, { items: [] });

    const rawAccounts = await fetchAccountList(link.accessToken, link.userSeqNo);
    const items = await Promise.all(
      rawAccounts.map(async (account) => ({
        id: account.fintech_use_num,
        bankName: account.bank_name,
        maskedAccountNumber: maskAccountNumber(account.account_num_masked || account.account_num),
        balance: await fetchBalance(link.accessToken, account.fintech_use_num),
        lastSyncedAt: new Date().toISOString(),
      })),
    );
    sendJson(response, 200, { items });
  } catch (error) {
    sendJson(response, 502, { error: error.message });
  }
}

async function handleRefreshAccount(request, response, accountId) {
  const auth = await verifyRequestAuth(request);
  if (!auth) return sendJson(response, 401, { error: '로그인이 필요해요.' });

  try {
    const link = await loadLink(auth.uid);
    if (!link) return sendJson(response, 404, { error: '연결된 계좌가 없어요.' });

    const balance = await fetchBalance(link.accessToken, accountId);
    sendJson(response, 200, {
      id: accountId,
      balance,
      lastSyncedAt: new Date().toISOString(),
    });
  } catch (error) {
    sendJson(response, 502, { error: error.message });
  }
}

async function handleUnlink(request, response) {
  const auth = await verifyRequestAuth(request);
  if (!auth) return sendJson(response, 401, { error: '로그인이 필요해요.' });

  try {
    const link = await loadLink(auth.uid);
    if (link) {
      await revokeConsent(link.accessToken, link.userSeqNo);
      const db = getFirestore();
      await db
        .collection('users')
        .doc(auth.uid)
        .collection('bankLink')
        .doc('openbanking')
        .delete();
    }
    sendJson(response, 200, { unlinked: true });
  } catch (error) {
    sendJson(response, 502, { error: error.message });
  }
}

/**
 * server.mjs의 handleRequest에서 호출.
 * 매치되는 라우트가 없으면 false를 반환해서 기존 라우팅으로 넘어가게 함.
 */
export async function handleAccountsRoute(request, response, url) {
  if (request.method === 'POST' && url.pathname === '/api/accounts/link/start') {
    await handleLinkStart(request, response);
    return true;
  }
  if (request.method === 'GET' && url.pathname === '/api/accounts/link/callback') {
    await handleLinkCallback(url, response);
    return true;
  }
  if (request.method === 'GET' && url.pathname === '/api/accounts') {
    await handleListAccounts(request, response);
    return true;
  }
  const refreshMatch = url.pathname.match(/^\/api\/accounts\/([^/]+)\/refresh$/);
  if (request.method === 'POST' && refreshMatch) {
    await handleRefreshAccount(request, response, refreshMatch[1]);
    return true;
  }
  if (request.method === 'DELETE' && url.pathname.match(/^\/api\/accounts\/[^/]+$/)) {
    await handleUnlink(request, response);
    return true;
  }
  return false;
}
