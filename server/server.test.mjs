import assert from 'node:assert/strict';
import test from 'node:test';

import {
  buildHealthPayload,
  normalizeInsights,
  normalizeIntent,
  normalizeShoppingResults,
  resolveWatsonxChatTarget,
  shouldInterpretQuery,
} from './server.mjs';

test('health contract advertises the spending insights route', () => {
  const health = buildHealthPayload({
    WATSONX_API_KEY: 'configured',
    WATSONX_PROJECT_ID: 'configured',
    WATSONX_URL: 'https://example.com',
    WATSONX_MODEL_ID: 'ibm/granite-4-h-small',
    SERPAPI_API_KEY: 'configured',
  });

  assert.equal(health.service, 'ibank-manager-api');
  assert.equal(health.apiVersion, 2);
  assert.equal(health.routes.spendingInsights, true);
  assert.equal(health.configured.spendingInsights, true);
});

test('normalizes watsonx search intent without inventing a price', () => {
  assert.deepEqual(
    normalizeIntent(
      { searchQuery: '노이즈 캔슬링 헤드폰', maxPrice: 300000 },
      'fallback',
    ),
    { searchQuery: '노이즈 캔슬링 헤드폰', maxPrice: 300000 },
  );
  assert.deepEqual(normalizeIntent({}, '무선 키보드'), {
    searchQuery: '무선 키보드',
    maxPrice: null,
  });
});

test('uses watsonx only when a query needs budget interpretation', () => {
  assert.equal(shouldInterpretQuery('독거미 키보드'), false);
  assert.equal(shouldInterpretQuery('게임용 무선 키보드'), false);
  assert.equal(shouldInterpretQuery('10만원 이하 무선 키보드'), true);
  assert.equal(shouldInterpretQuery('예산 안에서 살 수 있는 헤드폰'), true);
});

test('maps live shopping fields and filters invalid or over-budget items', () => {
  const items = normalizeShoppingResults(
    {
      shopping_results: [
        {
          product_id: 'p1',
          title: '무선 키보드 A',
          extracted_price: 29900,
          thumbnail: 'https://example.com/a.jpg',
          product_link: 'https://shop.example.com/a',
          source: '테스트몰',
        },
        {
          product_id: 'p2',
          title: '비싼 키보드',
          extracted_price: 199000,
          thumbnail: 'https://example.com/b.jpg',
        },
        { title: '가격 없음', thumbnail: 'https://example.com/c.jpg' },
      ],
    },
    100000,
  );

  assert.deepEqual(items, [
    {
      id: 'p1',
      name: '무선 키보드 A',
      price: 29900,
      imageUrl: 'https://example.com/a.jpg',
      productUrl: 'https://shop.example.com/a',
      source: '테스트몰',
    },
  ]);
});

test('search and insights share the same watsonx model/project', () => {
  const env = {
    WATSONX_PROJECT_ID: 'project-general',
    WATSONX_MODEL_ID: 'ibm/granite-4-h-small',
  };

  assert.deepEqual(resolveWatsonxChatTarget(env), {
    modelId: 'ibm/granite-4-h-small',
    projectId: 'project-general',
  });
});

test('watsonx target is empty when model id is not configured', () => {
  const target = resolveWatsonxChatTarget({
    WATSONX_PROJECT_ID: 'project-general',
  });
  assert.deepEqual(target, { modelId: '', projectId: 'project-general' });
});

test('keeps at most three valid insight cards', () => {
  const insights = normalizeInsights({
    insights: [
      {
        id: 'delivery',
        title: '배달이 늘었어요',
        body: '한 끼만 줄여 보세요.',
        actionLabel: '배달 내역 확인하기',
        actionCategory: '배달',
      },
      { title: '제목만 있고 본문이 없어요' },
      {
        title: '카페를 줄여 보세요',
        body: '일주일에 한 잔만 줄여도 목표가 당겨져요.',
        actionCategory: '카페',
      },
      {
        title: '구독 점검',
        body: '안 쓰는 구독이 있는지 확인해 보세요.',
      },
      {
        title: '네 번째 카드',
        body: '세 개까지만 보여주므로 무시되어야 해요.',
      },
    ],
  });

  assert.equal(insights.length, 3);
  assert.equal(insights[0].id, 'delivery');
  assert.equal(insights[1].actionLabel, '카페 내역 확인하기');
  assert.equal(insights[2].actionLabel, '목표 다시 보기');
  assert.equal(insights[2].actionCategory, '');
});
