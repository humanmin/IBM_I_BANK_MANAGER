import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import test from 'node:test';

import { encryptToken, decryptToken } from './token-crypto.mjs';

test('encrypts and decrypts a token round-trip', () => {
  const key = crypto.randomBytes(32).toString('hex'); // 테스트 전용 무작위 키, 실제 Secret 아님
  const plain = 'sample-access-token-value';

  const encrypted = encryptToken(plain, key);
  assert.notEqual(encrypted, plain);

  const decrypted = decryptToken(encrypted, key);
  assert.equal(decrypted, plain);
});

test('fails to decrypt with the wrong key', () => {
  const key = crypto.randomBytes(32).toString('hex');
  const wrongKey = crypto.randomBytes(32).toString('hex');
  const encrypted = encryptToken('secret-value', key);

  assert.throws(() => decryptToken(encrypted, wrongKey));
});
