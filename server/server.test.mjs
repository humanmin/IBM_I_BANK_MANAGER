import assert from 'node:assert/strict';
import test from 'node:test';

import {
  normalizeIntent,
  normalizeShoppingResults,
  shouldInterpretQuery,
} from './server.mjs';

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
