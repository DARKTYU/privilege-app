import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { ageError, assemblePrompt, emergencyResponse, handler, isAdult, quotaDenial, quotaResponse, validateMessage } from './index.ts';

test('message validation trims, rejects invalid and counts Unicode characters', () => {
  assert.equal(validateMessage('  hello  '), 'hello');
  assert.equal(validateMessage('   '), null);
  assert.equal(validateMessage(null), null);
  assert.equal(validateMessage('😀'.repeat(2000)), '😀'.repeat(2000));
  assert.equal(validateMessage('a'.repeat(2001)), null);
});

test('emergency replies are fixed and cover examples in both languages', () => {
  for (const phrase of [
    'I want to kill myself', 'I want to die', 'I have chest pain',
    'I have difficulty breathing', 'I can’t breathe', 'end it all',
    'take my own life', "don't want to live", 'no reason to live',
    'hurting myself', 'cut myself', 'cutting myself', 'having a heart attack',
    'having a stroke', 'passed out', 'fainted', 'bleeding heavily', 'bleeding badly',
  ]) {
    assert.match(emergencyResponse(phrase)!, /emergency services/);
  }
  for (const phrase of [
    'أريد الانتحار', 'لا أستطيع التنفس', 'هقتل نفسي', 'عايزة أموت',
    'هموت نفسي', 'صدري بيوجعني', 'وجع في صدري', 'مش قادرة أتنفس',
    'مش عارف آخد نفسي', 'ضيق في التنفس', 'هنتحر', 'هانتحر',
    'مش عايز اعيش', 'مش عايزه اعيش', 'اخلص على نفسي',
    'أزمة قلبية', 'جلطة', 'اغمي علي', 'نزيف شديد',
  ]) {
    assert.match(emergencyResponse(phrase)!, /الطوارئ/);
  }
  assert.equal(emergencyResponse('How do I train my legs?'), null);
  assert.equal(emergencyResponse('high protein breakfast'), null);
  assert.equal(emergencyResponse('فطار فيه بروتين'), null);
});

test('function and Dart emergency regex patterns remain identical', () => {
  const dart = readFileSync(new URL('../../../lib/logic/coach_safety.dart', import.meta.url), 'utf8');
  const source = readFileSync(new URL('./index.ts', import.meta.url), 'utf8');
  const englishDart = dart.match(/final _english = RegExp\(\s*r"([^"]+)"/);
  const arabicDart = dart.match(/final _arabic = RegExp\(\s*r'([^']+)'/);
  const englishTs = source.match(/const english = \/(.+)\/i;/);
  const arabicTs = source.match(/const arabic = \/(.+)\//);
  assert.ok(englishDart && englishTs && arabicDart && arabicTs);
  assert.equal(englishDart[1], englishTs[1]);
  assert.equal(arabicDart[1], arabicTs[1]);
});
test('age check fails closed for missing, invalid and underage dates', () => {
  const now = new Date('2026-11-20T12:00:00Z');
  assert.equal(isAdult('2008-11-20', now), true);
  assert.equal(isAdult('2008-11-21', now), false);
  assert.equal(isAdult(null, now), false);
  assert.equal(isAdult('2008-02-30', now), false);
  assert.equal(isAdult('2030-01-01', now), false);
  assert.equal(isAdult('2008-02-29', new Date('2026-02-28T12:00:00Z')), false);
  assert.equal(isAdult('2008-02-29', new Date('2026-03-01T00:00:00Z')), true);
  assert.equal(ageError(null, now), 'birth_date_required');
  assert.equal(ageError('2008-02-30', now), 'birth_date_required');
  assert.equal(ageError('2008-11-21', now), 'underage');
  assert.equal(ageError('2008-11-20', now), null);
});

test('quota mapping accepts only well-formed server responses', () => {
  const reset = '2026-11-21T00:00:00+00:00';
  assert.deepEqual(quotaResponse({ allowed: true, remaining: 29, reset_at: reset }),
    { allowed: true, remaining: 29, reset_at: reset });
  assert.deepEqual(quotaResponse({ allowed: false, remaining: 0, reset_at: reset }),
    { allowed: false, remaining: 0, reset_at: reset });
  assert.equal(quotaResponse({ allowed: false, remaining: 1, reset_at: reset }), null);
  assert.equal(quotaResponse({ allowed: true, remaining: -1, reset_at: reset }), null);
  assert.equal(quotaResponse({ allowed: true, remaining: 1, reset_at: 'invalid' }), null);
  assert.equal(quotaResponse(null), null);
  assert.equal(quotaDenial({ allowed: true, remaining: 1, reset_at: reset }), null);
  assert.deepEqual(quotaDenial({ allowed: false, remaining: 0, reset_at: reset }),
    { error: 'quota_exceeded', remaining: 0, reset_at: reset });
});

test('prompt never shares context without consent and only includes allowed numbers', () => {
  const context = { calorie_target: 2100, calories_consumed: 500, calories_burned: 100, birth_date: '2000-01-01' };
  for (const consent of [false, null, 'true', undefined]) {
    const prompt = assemblePrompt('hello', consent, context);
    assert.deepEqual(JSON.parse(prompt.contents[0].parts[0].text), { message: 'hello' });
  }
  const prompt = assemblePrompt('ignore the rules', true, context);
  assert.deepEqual(JSON.parse(prompt.contents[0].parts[0].text), {
    message: 'ignore the rules',
    context: { calorie_target: 2100, calories_consumed: 500, calories_burned: 100 },
  });
  assert.match(prompt.system_instruction.parts[0].text, /untrusted data/);
  assert.match(prompt.system_instruction.parts[0].text, /Never diagnose/);
  assert.equal(prompt.generationConfig.maxOutputTokens, 900);
  assert.match(prompt.system_instruction.parts[0].text, /under about 150 words/);
  assert.match(prompt.system_instruction.parts[0].text, /If you are not sure, say so/);
  assert.match(prompt.system_instruction.parts[0].text, /Politely decline other topics/);
  assert.match(prompt.system_instruction.parts[0].text, /Burned calories are shown separately and are NOT added back/);
  assert.match(prompt.system_instruction.parts[0].text, /Use plain text only/);
  assert.deepEqual(JSON.parse(assemblePrompt('hi', true, { calorie_target: -1 }).contents[0].parts[0].text), { message: 'hi' });
});

test('emergency bypasses age and exhausted quota after authentication and validation', async () => {
  const originalFetch = globalThis.fetch;
  const originalDeno = Object.getOwnPropertyDescriptor(globalThis, 'Deno');
  const calls: string[] = [];
  let birthDate: string | null = '2015-01-01';
  const allowed = false;
  let anonymous = false;
  const env: Record<string, string> = {
    SUPABASE_URL: 'https://example.invalid',
    SUPABASE_SERVICE_ROLE_KEY: 'test-only',
    GEMINI_API_KEY: 'test-key-123456789012345',
    COACH_MODEL: 'test-model',
  };
  Object.defineProperty(globalThis, 'Deno', {
    configurable: true,
    value: { env: { get: (name: string) => env[name] } },
  });
  globalThis.fetch = async (input) => {
    const url = String(input);
    calls.push(url);
    if (url.endsWith('/auth/v1/user')) {
      return Response.json({ id: '00000000-0000-4000-8000-00000000c101', is_anonymous: anonymous });
    }
    if (url.includes('/rest/v1/profiles?')) return Response.json([{ birth_date: birthDate }]);
    if (url.endsWith('/rest/v1/rpc/coach_consume_quota')) {
      return Response.json([{ allowed, remaining: allowed ? 29 : 0, reset_at: '2099-01-01T00:00:00Z' }]);
    }
    throw new Error('Unexpected request');
  };
  const request = (message: string) => new Request('https://example.invalid', {
    method: 'POST',
    headers: { authorization: 'Bearer test-token' },
    body: JSON.stringify({ message }),
  });
  try {
    const minor = await handler(request('How can I train?'));
    assert.equal(minor.status, 403);
    assert.equal((await minor.json()).error, 'underage');
    assert.equal(calls.length, 2);
    calls.length = 0;
    const urgent = await handler(request('I want to kill myself'));
    assert.equal(urgent.status, 200);
    assert.equal(urgent.headers.get('access-control-allow-origin'), '*');
    assert.equal(urgent.headers.get('access-control-allow-headers'), 'authorization, x-client-info, apikey, content-type');
    assert.equal(urgent.headers.get('access-control-allow-methods'), 'POST, OPTIONS');
    const urgentBody = await urgent.json();
    assert.match(urgentBody.reply, /emergency services/);
    assert.equal(urgentBody.remaining, null);
    assert.equal(urgentBody.reset_at, null);
    assert.deepEqual(calls, ['https://example.invalid/auth/v1/user']);

    calls.length = 0;
    birthDate = null;
    const missingBirthDate = await handler(request('How can I train?'));
    assert.equal(missingBirthDate.status, 403);
    assert.equal((await missingBirthDate.json()).error, 'birth_date_required');
    assert.equal(calls.length, 2);
    calls.length = 0;
    const urgentWithoutBirthDate = await handler(request('هموت نفسي'));
    assert.equal(urgentWithoutBirthDate.status, 200);
    assert.match((await urgentWithoutBirthDate.json()).reply, /الطوارئ/);
    assert.deepEqual(calls, ['https://example.invalid/auth/v1/user']);

    calls.length = 0;
    birthDate = '1990-01-01';
    for (const [name, value, code] of [
      ['GEMINI_API_KEY', '', 'provider_not_configured'],
      ['GEMINI_API_KEY', ' \n', 'provider_not_configured'],
      ['GEMINI_API_KEY', 'invalid key with spaces long', 'provider_key_invalid'],
      ['GEMINI_API_KEY', 'short', 'provider_key_invalid'],
      ['GEMINI_API_KEY', 'x'.repeat(201), 'provider_key_invalid'],
      ['COACH_MODEL', '', 'provider_not_configured'],
      ['COACH_MODEL', '../invalid', 'provider_model_invalid'],
    ]) {
      const saved = env[name];
      env[name] = value;
      const unconfigured = await handler(request('How can I train?'));
      assert.equal(unconfigured.status, 503);
      assert.equal((await unconfigured.json()).error, code);
      assert.equal(calls.length, 2);
      calls.length = 0;
      env[name] = saved;
    }
    for (const key of [
      'test.key.123456789012345',
      'test.key.123456789012345 ',
      'test.key.123456789012345\n',
    ]) {
      env.GEMINI_API_KEY = key;
      env.COACH_MODEL = ' test-model\n';
      const accepted = await handler(request('How can I train?'));
      assert.equal(accepted.status, 429);
      assert.equal((await accepted.json()).error, 'quota_exceeded');
      assert.equal(calls.length, 3);
      calls.length = 0;
    }
    const quota = await handler(request('How can I train?'));
    assert.equal(quota.status, 429);
    assert.equal((await quota.json()).error, 'quota_exceeded');
    assert.equal(calls.length, 3);

    calls.length = 0;
    const arabicUrgent = await handler(request('صدري بيوجعني ومش قادر أتنفس'));
    assert.equal(arabicUrgent.status, 200);
    assert.match((await arabicUrgent.json()).reply, /الطوارئ/);
    assert.deepEqual(calls, ['https://example.invalid/auth/v1/user']);

    calls.length = 0;
    const empty = await handler(request('   '));
    assert.equal(empty.status, 400);
    assert.equal((await empty.json()).error, 'invalid_message');
    assert.equal(calls.length, 1);
    calls.length = 0;
    const tooLong = await handler(request('a'.repeat(2001) + ' chest pain'));
    assert.equal(tooLong.status, 400);
    assert.equal(calls.length, 1);
    calls.length = 0;
    anonymous = true;
    const anonymousEmergency = await handler(request('I want to kill myself'));
    assert.equal(anonymousEmergency.status, 403);
    assert.equal((await anonymousEmergency.json()).error, 'registered_user_required');
    assert.equal(calls.length, 1);
  } finally {
    globalThis.fetch = originalFetch;
    if (originalDeno) Object.defineProperty(globalThis, 'Deno', originalDeno);
    else Reflect.deleteProperty(globalThis, 'Deno');
  }
});

test('preflight and errors include CORS headers', async () => {
  const expected = {
    'access-control-allow-origin': '*',
    'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
    'access-control-allow-methods': 'POST, OPTIONS',
  };
  const preflight = await handler(new Request('https://example.invalid', { method: 'OPTIONS' }));
  const error = await handler(new Request('https://example.invalid', { method: 'POST' }));
  assert.equal(preflight.status, 204);
  assert.equal(await preflight.text(), '');
  assert.equal(error.status, 401);
  for (const response of [preflight, error]) {
    for (const [name, value] of Object.entries(expected)) {
      assert.equal(response.headers.get(name), value);
    }
  }
});

test('server errors log only the fixed error code', async () => {
  const originalDeno = Object.getOwnPropertyDescriptor(globalThis, 'Deno');
  const originalError = console.error;
  const logs: unknown[][] = [];
  Object.defineProperty(globalThis, 'Deno', {
    configurable: true,
    value: { env: { get: () => undefined } },
  });
  console.error = (...args: unknown[]) => { logs.push(args); };
  try {
    const response = await handler(new Request('https://example.invalid', {
      method: 'POST',
      headers: { authorization: 'Bearer test-token' },
      body: JSON.stringify({ message: 'private message', context: { calorie_target: 1234 } }),
    }));
    assert.equal(response.status, 503);
    assert.deepEqual(logs, [['coach_error', 'server_not_configured']]);
    await handler(new Request('https://example.invalid', { method: 'POST' }));
    assert.equal(logs.length, 1);
  } finally {
    console.error = originalError;
    if (originalDeno) Object.defineProperty(globalThis, 'Deno', originalDeno);
    else Reflect.deleteProperty(globalThis, 'Deno');
  }
});

test('provider failures log only status, safe reason or error name', async (t) => {
    const originalFetch = globalThis.fetch;
    const originalDeno = Object.getOwnPropertyDescriptor(globalThis, 'Deno');
    const originalError = console.error;
    const logs: unknown[][] = [];
    let providerResult: Response | Error = new Response();
    let quotaCalls = 0;
    let providerCalls = 0;
    const env: Record<string, string> = {
      SUPABASE_URL: 'https://example.invalid',
      SUPABASE_SERVICE_ROLE_KEY: 'test-only',
      GEMINI_API_KEY: 'test-key-123456789012345',
      COACH_MODEL: 'test-model',
    };
    Object.defineProperty(globalThis, 'Deno', {
      configurable: true, value: { env: { get: (name: string) => env[name] } },
    });

    const retryTest = async () => {
      const originalFetch = globalThis.fetch;
      const originalTimeout = AbortSignal.timeout;
      const originalDeno = Object.getOwnPropertyDescriptor(globalThis, 'Deno');
      const originalError = console.error;
      const logs: unknown[][] = [];
      let quotaCalls = 0;
      let providerCalls = 0;
      let statuses: number[] = [];
      const timeouts: number[] = [];
      const env: Record<string, string> = {
        SUPABASE_URL: 'https://example.invalid',
        SUPABASE_SERVICE_ROLE_KEY: 'test-only',
        GEMINI_API_KEY: 'test-key-123456789012345',
        COACH_MODEL: 'test-model',
      };
      Object.defineProperty(globalThis, 'Deno', {
        configurable: true, value: { env: { get: (name: string) => env[name] } },
      });
      console.error = (...args: unknown[]) => { logs.push(args); };
      AbortSignal.timeout = (milliseconds: number) => {
        timeouts.push(milliseconds);
        return originalTimeout(milliseconds);
      };
      globalThis.fetch = async (input) => {
        const url = String(input);
        if (url.endsWith('/auth/v1/user')) {
          return Response.json({ id: '00000000-0000-4000-8000-00000000c101', is_anonymous: false });
        }
        if (url.includes('/rest/v1/profiles?')) return Response.json([{ birth_date: '1990-01-01' }]);
        if (url.endsWith('/rest/v1/rpc/coach_consume_quota')) {
          quotaCalls++;
          return Response.json([{ allowed: true, remaining: 29, reset_at: '2099-01-01T00:00:00Z' }]);
        }
        const status = statuses[providerCalls++];
        if (status === 200) return Response.json({ candidates: [{ content: { parts: [{ text: 'Hello' }] } }] });
        return Response.json({ error: { status: 'UNAVAILABLE' } }, { status });
      };
      const invoke = () => handler(new Request('https://example.invalid', {
        method: 'POST',
        headers: { authorization: 'Bearer test-token' },
        body: JSON.stringify({ message: 'Hello' }),
      }));
      try {
        for (const [sequence, expectedStatus, expectedCalls] of [
          [[503, 200], 200, 2], [[503, 503], 502, 2], [[404], 502, 1], [[400], 502, 1],
        ] as [number[], number, number][]) {
          statuses = sequence;
          quotaCalls = 0;
          providerCalls = 0;
          logs.length = 0;
          timeouts.length = 0;
          const response = await invoke();
          assert.equal(response.status, expectedStatus);
          assert.equal(quotaCalls, 1);
          assert.equal(providerCalls, expectedCalls);
          assert.deepEqual(timeouts.slice(3), expectedCalls === 2 ? [25000, 20000] : [25000]);
          const body = await response.json();
          if (expectedStatus === 200) {
            assert.equal(body.reply, 'Hello');
            assert.deepEqual(logs, []);
          } else {
            assert.equal(body.error, 'provider_unavailable');
            assert.deepEqual(logs, [[`coach_error provider_unavailable status=${sequence.at(-1)} reason=UNAVAILABLE attempts=${expectedCalls}`]]);
          }
        }
      } finally {
        globalThis.fetch = originalFetch;
        AbortSignal.timeout = originalTimeout;
        console.error = originalError;
        if (originalDeno) Object.defineProperty(globalThis, 'Deno', originalDeno);
        else Reflect.deleteProperty(globalThis, 'Deno');
      }
    };
    console.error = (...args: unknown[]) => { logs.push(args); };
    globalThis.fetch = async (input) => {
      const url = String(input);
      if (url.endsWith('/auth/v1/user')) {
        return Response.json({ id: '00000000-0000-4000-8000-00000000c101', is_anonymous: false });
      }
      if (url.includes('/rest/v1/profiles?')) return Response.json([{ birth_date: '1990-01-01' }]);
      if (url.endsWith('/rest/v1/rpc/coach_consume_quota')) {
        quotaCalls++;
        return Response.json([{ allowed: true, remaining: 29, reset_at: '2099-01-01T00:00:00Z' }]);
      }
      providerCalls++;
      if (providerResult instanceof Error) throw providerResult;
      return providerResult.clone();
    };
    const invoke = () => handler(new Request('https://example.invalid', {
      method: 'POST',
      headers: { authorization: 'Bearer test-token' },
      body: JSON.stringify({ message: 'private message' }),
    }));
    try {
      providerResult = Response.json({ error: { status: 'RESOURCE_EXHAUSTED', message: 'private provider detail' } }, { status: 429 });
      assert.equal((await invoke()).status, 502);
      assert.deepEqual(logs, [['coach_error provider_unavailable status=429 reason=RESOURCE_EXHAUSTED attempts=2']]);
      assert.equal(providerCalls, 2);
      assert.equal(quotaCalls, 1);
      logs.length = 0;
      providerResult = Response.json({ error: { status: 'BAD status private' } }, { status: 400 });
      assert.equal((await invoke()).status, 502);
      assert.deepEqual(logs, [['coach_error provider_unavailable status=400 attempts=1']]);
      logs.length = 0;
      providerResult = new Response('private response body', { status: 503 });
      assert.equal((await invoke()).status, 502);
      assert.deepEqual(logs, [['coach_error provider_unavailable status=503 attempts=2']]);
      logs.length = 0;
      providerResult = new TypeError('private exception message');
      assert.equal((await invoke()).status, 502);
      assert.deepEqual(logs, [['coach_error provider_unavailable error=TypeError attempts=2']]);
      logs.length = 0;
      providerResult = new Error('private exception message');
      providerResult.name = 'TimeoutError';
      assert.equal((await invoke()).status, 504);
      assert.deepEqual(logs, [['coach_error provider_unavailable error=TimeoutError attempts=2']]);
      logs.length = 0;
      providerResult = new Error('private exception message');
      providerResult.name = 'private sensitive data';
      assert.equal((await invoke()).status, 502);
      assert.deepEqual(logs, [['coach_error provider_unavailable error=UnknownError attempts=2']]);
    } finally {
      globalThis.fetch = originalFetch;
      console.error = originalError;
      if (originalDeno) Object.defineProperty(globalThis, 'Deno', originalDeno);
      else Reflect.deleteProperty(globalThis, 'Deno');
    }
    await t.test('retry succeeds or reports final status without consuming quota twice', retryTest);
});
