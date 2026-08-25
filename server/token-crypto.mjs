import crypto from 'node:crypto';

const ALGORITHM = 'aes-256-gcm';

/**
 * 순수 함수 모음 — 실제 키(TOKEN_ENCRYPTION_KEY)는 호출부에서 주입받습니다.
 * 이렇게 분리해두면 테스트에서 무작위로 만든 키로 암복호화 왕복만 검증할 수 있어서
 * (server.test.mjs가 지켜온 원칙대로) 실제 Secret 없이도 CI에서 테스트 가능합니다.
 */

export function encryptToken(plainText, keyHex) {
  const key = Buffer.from(keyHex, 'hex');
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
  const encrypted = Buffer.concat([cipher.update(plainText, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return [iv, authTag, encrypted].map((b) => b.toString('base64')).join('.');
}

export function decryptToken(payload, keyHex) {
  const key = Buffer.from(keyHex, 'hex');
  const [ivB64, authTagB64, dataB64] = payload.split('.');
  const iv = Buffer.from(ivB64, 'base64');
  const authTag = Buffer.from(authTagB64, 'base64');
  const data = Buffer.from(dataB64, 'base64');
  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(authTag);
  return Buffer.concat([decipher.update(data), decipher.final()]).toString('utf8');
}
