import { getAuth } from 'firebase-admin/auth';
import { initializeApp, cert, getApps } from 'firebase-admin/app';

function ensureFirebaseApp() {
  if (getApps().length) return;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON 설정이 필요합니다.');
  }
  initializeApp({ credential: cert(JSON.parse(raw)) });
}

/**
 * Authorization: Bearer <idToken> 헤더를 검증하고 uid를 반환합니다.
 * 실패하면 null을 반환합니다 (호출부에서 401 응답 처리).
 */
export async function verifyRequestAuth(request) {
  const header = request.headers.authorization || '';
  const match = header.match(/^Bearer (.+)$/);
  if (!match) return null;

  try {
    ensureFirebaseApp();
    const decoded = await getAuth().verifyIdToken(match[1]);
    return { uid: decoded.uid, email: decoded.email ?? null };
  } catch {
    return null;
  }
}
