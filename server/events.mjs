import { getFirestore } from 'firebase-admin/firestore';

import { verifyRequestAuth } from './auth-middleware.mjs';

function sendJson(response, statusCode, data) {
  response.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'Access-Control-Allow-Origin': process.env.ALLOWED_ORIGIN || '*',
  });
  response.end(JSON.stringify(data));
}

function todayKey(date = new Date()) {
  return date.toISOString().slice(0, 10); // YYYY-MM-DD
}

function isConsecutiveDay(lastDateStr, today) {
  if (!lastDateStr) return false;
  const last = new Date(`${lastDateStr}T00:00:00Z`);
  const diffDays = Math.round((today - last) / 86_400_000);
  return diffDays === 1;
}

function userDoc(uid) {
  return getFirestore().collection('users').doc(uid);
}

function pointLedgerCol(uid) {
  return userDoc(uid).collection('pointLedger');
}

async function currentPointBalance(uid) {
  const snapshot = await pointLedgerCol(uid).get();
  let totalPoints = 0;
  snapshot.forEach((doc) => {
    totalPoints += doc.data().delta || 0;
  });
  const profile = await userDoc(uid).collection('meta').doc('points').get();
  const data = profile.exists ? profile.data() : {};
  return {
    totalPoints,
    currentStreakDays: data.currentStreakDays || 0,
    lastCheckInDate: data.lastCheckInDate || null,
  };
}

// ── GET /api/events/points ──────────────────────────────────────────
async function handlePoints(request, response) {
  const auth = await verifyRequestAuth(request);
  if (!auth) return sendJson(response, 401, { error: '로그인이 필요해요.' });

  try {
    sendJson(response, 200, await currentPointBalance(auth.uid));
  } catch (error) {
    sendJson(response, 500, { error: error.message });
  }
}

// ── POST /api/events/checkin ────────────────────────────────────────
async function handleCheckIn(request, response) {
  const auth = await verifyRequestAuth(request);
  if (!auth) return sendJson(response, 401, { error: '로그인이 필요해요.' });

  const today = new Date();
  const todayStr = todayKey(today);

  try {
    const metaRef = userDoc(auth.uid).collection('meta').doc('points');
    const metaSnap = await metaRef.get();
    const meta = metaSnap.exists ? metaSnap.data() : {};

    if (meta.lastCheckInDate === todayStr) {
      return sendJson(response, 409, { error: '오늘은 이미 출석했어요.' });
    }

    const newStreak = isConsecutiveDay(meta.lastCheckInDate, today)
      ? (meta.currentStreakDays || 0) + 1
      : 1;
    const earned = 50;

    await pointLedgerCol(auth.uid).add({
      delta: earned,
      reason: 'checkin',
      createdAt: today.toISOString(),
    });
    await metaRef.set(
      { currentStreakDays: newStreak, lastCheckInDate: todayStr },
      { merge: true },
    );

    const balance = await currentPointBalance(auth.uid);
    sendJson(response, 200, { ...balance, pointsEarned: earned });
  } catch (error) {
    sendJson(response, 500, { error: error.message });
  }
}

// ── GET /api/events/surveys ─────────────────────────────────────────
async function handleSurveys(request, response) {
  const auth = await verifyRequestAuth(request);
  if (!auth) return sendJson(response, 401, { error: '로그인이 필요해요.' });

  try {
    const db = getFirestore();
    const surveysSnap = await db
      .collection('surveys')
      .where('active', '==', true)
      .get();
    const responsesSnap = await userDoc(auth.uid)
      .collection('surveyResponses')
      .get();
    const completedIds = new Set(responsesSnap.docs.map((doc) => doc.id));

    const items = surveysSnap.docs.map((doc) => ({
      id: doc.id,
      title: doc.data().title,
      durationLabel: doc.data().durationLabel,
      rewardPoints: doc.data().rewardPoints,
      completed: completedIds.has(doc.id),
    }));
    sendJson(response, 200, { items });
  } catch (error) {
    sendJson(response, 500, { error: error.message });
  }
}

// ── POST /api/events/surveys/:id/response ───────────────────────────
async function handleSurveyResponse(request, response, surveyId, body) {
  const auth = await verifyRequestAuth(request);
  if (!auth) return sendJson(response, 401, { error: '로그인이 필요해요.' });

  try {
    const db = getFirestore();
    const surveyRef = db.collection('surveys').doc(surveyId);
    const surveySnap = await surveyRef.get();
    if (!surveySnap.exists) {
      return sendJson(response, 404, { error: '존재하지 않는 설문이에요.' });
    }

    const responseRef = userDoc(auth.uid)
      .collection('surveyResponses')
      .doc(surveyId);
    const already = await responseRef.get();
    if (already.exists) {
      return sendJson(response, 409, { error: '이미 참여한 설문이에요.' });
    }

    const rewardPoints = surveySnap.data().rewardPoints || 0;
    await responseRef.set({
      answers: body?.answers ?? [],
      createdAt: new Date().toISOString(),
    });
    await pointLedgerCol(auth.uid).add({
      delta: rewardPoints,
      reason: 'survey',
      surveyId,
      createdAt: new Date().toISOString(),
    });

    const balance = await currentPointBalance(auth.uid);
    sendJson(response, 200, {
      pointsEarned: rewardPoints,
      totalPoints: balance.totalPoints,
    });
  } catch (error) {
    sendJson(response, 500, { error: error.message });
  }
}

// ── GET /api/events/referral ────────────────────────────────────────
const REWARD_PER_INVITE = 200;
const MAX_REFERRAL_REWARD = 1000;

function referralCodeFor(uid) {
  return uid.slice(0, 8).toUpperCase();
}

async function handleReferral(request, response) {
  const auth = await verifyRequestAuth(request);
  if (!auth) return sendJson(response, 401, { error: '로그인이 필요해요.' });

  try {
    const db = getFirestore();
    const eventsSnap = await db
      .collection('referralEvents')
      .where('referrerUid', '==', auth.uid)
      .get();
    const earnedPoints = eventsSnap.docs.reduce(
      (sum, doc) => sum + (doc.data().pointsAwarded || 0),
      0,
    );
    sendJson(response, 200, {
      code: referralCodeFor(auth.uid),
      invitedCount: eventsSnap.size,
      earnedPoints,
      rewardPerInvite: REWARD_PER_INVITE,
      maxRewardPoints: MAX_REFERRAL_REWARD,
    });
  } catch (error) {
    sendJson(response, 500, { error: error.message });
  }
}

// ── GET /api/events/rewards ─────────────────────────────────────────
async function handleRewards(request, response) {
  const auth = await verifyRequestAuth(request);
  if (!auth) return sendJson(response, 401, { error: '로그인이 필요해요.' });

  try {
    const db = getFirestore();
    const snap = await db.collection('rewards').where('inStock', '==', true).get();
    const items = snap.docs.map((doc) => ({
      id: doc.id,
      name: doc.data().name,
      costPoints: doc.data().costPoints,
      category: doc.data().category,
      inStock: doc.data().inStock,
    }));
    sendJson(response, 200, { items });
  } catch (error) {
    sendJson(response, 500, { error: error.message });
  }
}

// ── POST /api/events/rewards/:id/redeem ──────────────────────────────
async function handleRedeem(request, response, rewardId) {
  const auth = await verifyRequestAuth(request);
  if (!auth) return sendJson(response, 401, { error: '로그인이 필요해요.' });

  try {
    const db = getFirestore();
    const rewardSnap = await db.collection('rewards').doc(rewardId).get();
    if (!rewardSnap.exists) {
      return sendJson(response, 404, { error: '존재하지 않는 리워드예요.' });
    }
    const cost = rewardSnap.data().costPoints || 0;
    const balance = await currentPointBalance(auth.uid);
    if (balance.totalPoints < cost) {
      return sendJson(response, 400, { error: '포인트가 부족해요.' });
    }

    await pointLedgerCol(auth.uid).add({
      delta: -cost,
      reason: 'redeem',
      rewardId,
      createdAt: new Date().toISOString(),
    });
    await userDoc(auth.uid).collection('redemptions').add({
      rewardId,
      createdAt: new Date().toISOString(),
      status: 'redeemed', // 실물 발송 없음 — 데모 상태 전환까지만
    });

    sendJson(response, 200, { redeemed: true });
  } catch (error) {
    sendJson(response, 500, { error: error.message });
  }
}

async function readJsonBody(request) {
  const chunks = [];
  for await (const chunk of request) chunks.push(chunk);
  if (chunks.length === 0) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return {};
  }
}

/**
 * server.mjs의 handleRequest에서 호출.
 * 매치되는 라우트가 없으면 false를 반환해서 기존 라우팅으로 넘어가게 함.
 */
export async function handleEventsRoute(request, response, url) {
  if (request.method === 'GET' && url.pathname === '/api/events/points') {
    await handlePoints(request, response);
    return true;
  }
  if (request.method === 'POST' && url.pathname === '/api/events/checkin') {
    await handleCheckIn(request, response);
    return true;
  }
  if (request.method === 'GET' && url.pathname === '/api/events/surveys') {
    await handleSurveys(request, response);
    return true;
  }
  const surveyMatch = url.pathname.match(
    /^\/api\/events\/surveys\/([^/]+)\/response$/,
  );
  if (request.method === 'POST' && surveyMatch) {
    const body = await readJsonBody(request);
    await handleSurveyResponse(request, response, surveyMatch[1], body);
    return true;
  }
  if (request.method === 'GET' && url.pathname === '/api/events/referral') {
    await handleReferral(request, response);
    return true;
  }
  if (request.method === 'GET' && url.pathname === '/api/events/rewards') {
    await handleRewards(request, response);
    return true;
  }
  const redeemMatch = url.pathname.match(
    /^\/api\/events\/rewards\/([^/]+)\/redeem$/,
  );
  if (request.method === 'POST' && redeemMatch) {
    await handleRedeem(request, response, redeemMatch[1]);
    return true;
  }
  return false;
}
