/**
 * 오픈뱅킹 테스트베드(oben.kr) 클라이언트.
 *
 * 주의: 아래 엔드포인트 경로/파라미터명은 오픈뱅킹 표준 스펙 기준 "개념적" 흐름입니다.
 * 실제 연동 전 반드시 오픈뱅킹 테스트베드 개발가이드 최신 문서에서
 * 정확한 경로와 파라미터를 재확인하세요. (스펙 버전에 따라 세부사항이 다를 수 있음)
 */

function requireSetting(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`${name} 설정이 필요합니다.`);
  return value;
}

const OPENBANKING_BASE_URL =
  process.env.OPENBANKING_BASE_URL || 'https://testapi.openbanking.or.kr';

export function buildAuthorizeUrl(state) {
  const clientId = requireSetting('OPENBANKING_CLIENT_ID');
  const redirectUri = requireSetting('OPENBANKING_REDIRECT_URI');
  const url = new URL(`${OPENBANKING_BASE_URL}/oauth/2.0/authorize`);
  url.search = new URLSearchParams({
    response_type: 'code',
    client_id: clientId,
    redirect_uri: redirectUri,
    scope: 'login inquiry',
    state,
    auth_type: '0',
  }).toString();
  return url.toString();
}

export async function exchangeCodeForToken(code) {
  const clientId = requireSetting('OPENBANKING_CLIENT_ID');
  const clientSecret = requireSetting('OPENBANKING_CLIENT_SECRET');
  const redirectUri = requireSetting('OPENBANKING_REDIRECT_URI');

  const body = new URLSearchParams({
    code,
    client_id: clientId,
    client_secret: clientSecret,
    redirect_uri: redirectUri,
    grant_type: 'authorization_code',
  });

  const response = await fetch(`${OPENBANKING_BASE_URL}/oauth/2.0/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  const data = await response.json();
  if (!response.ok || !data.access_token) {
    throw new Error(data?.error_description || '오픈뱅킹 토큰 발급에 실패했습니다.');
  }
  return {
    accessToken: data.access_token,
    refreshToken: data.refresh_token,
    userSeqNo: data.user_seq_no,
  };
}

export async function fetchAccountList(accessToken, userSeqNo) {
  const url = new URL(`${OPENBANKING_BASE_URL}/v2.0/account/list`);
  url.search = new URLSearchParams({ user_seq_no: userSeqNo, include_cancel_yn: 'N' }).toString();
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data?.rsp_message || '계좌 목록 조회에 실패했습니다.');
  }
  return data.res_list || [];
}

export async function fetchBalance(accessToken, fintechUseNum) {
  const url = new URL(`${OPENBANKING_BASE_URL}/v2.0/account/balance/fin_num`);
  url.search = new URLSearchParams({
    bank_tran_id: `M${Date.now()}U001`, // 은행거래고유번호 — 실제로는 이용기관코드 규칙 준수 필요
    fintech_use_num: fintechUseNum,
    tran_dtime: new Date()
      .toISOString()
      .replace(/[-:TZ.]/g, '')
      .slice(0, 14),
  }).toString();
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data?.rsp_message || '잔액 조회에 실패했습니다.');
  }
  return Math.round(Number(data.balance_amt));
}

export async function revokeConsent(accessToken, userSeqNo) {
  const url = new URL(`${OPENBANKING_BASE_URL}/v2.0/user/${userSeqNo}`);
  const response = await fetch(url, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!response.ok) {
    throw new Error('오픈뱅킹 연결 해지에 실패했습니다.');
  }
}
