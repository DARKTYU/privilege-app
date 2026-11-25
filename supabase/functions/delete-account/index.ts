// Permanently deletes the signed-in user's account.
//
// Flow: verify the caller's JWT, remove the account's stored photos, then delete
// the auth user. Every user table uses ON DELETE CASCADE, so the database rows
// are removed by the auth deletion itself. Photos are removed first; if that
// step fails nothing else is deleted, so the user can simply try again.

type JsonObject = Record<string, unknown>;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const REMOVE_BATCH = 100;

function json(status: number, body: JsonObject): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
  });
}

export async function handler(request: Request): Promise<Response> {
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders });
  if (request.method !== 'POST') return json(405, { error: 'method_not_allowed' });
  const authorization = request.headers.get('authorization');
  if (!authorization || !/^Bearer \S+$/i.test(authorization)) {
    return json(401, { error: 'authentication_required' });
  }

  const url = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !serviceKey) return json(503, { error: 'server_not_configured' });
  const adminHeaders = { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` };

  try {
    const auth = await fetch(`${url}/auth/v1/user`, {
      headers: { apikey: serviceKey, Authorization: authorization },
      signal: AbortSignal.timeout(10000),
    });
    if (auth.status === 401 || auth.status === 403) {
      return json(401, { error: 'authentication_required' });
    }
    if (!auth.ok) return json(503, { error: 'authentication_unavailable' });
    const user = await auth.json();
    if (typeof user.id !== 'string' || !UUID.test(user.id) || user.is_anonymous !== false) {
      return json(403, { error: 'registered_user_required' });
    }

    let input: unknown;
    try {
      input = await request.json();
    } catch {
      return json(400, { error: 'invalid_request_body' });
    }
    if (!input || typeof input !== 'object' || (input as JsonObject).confirm !== 'DELETE') {
      return json(400, { error: 'confirmation_required' });
    }

    // 1. Find every stored photo that belongs to this account.
    const listed = await fetch(`${url}/rest/v1/rpc/account_storage_paths`, {
      method: 'POST',
      headers: { ...adminHeaders, 'Content-Type': 'application/json' },
      body: JSON.stringify({ p_user: user.id }),
      signal: AbortSignal.timeout(15000),
    });
    if (!listed.ok) return json(503, { error: 'storage_lookup_failed' });
    const rows = await listed.json();
    if (!Array.isArray(rows)) return json(503, { error: 'storage_lookup_failed' });

    const byBucket = new Map<string, string[]>();
    for (const row of rows) {
      if (!row || typeof row.bucket !== 'string' || typeof row.path !== 'string') continue;
      const list = byBucket.get(row.bucket) ?? [];
      list.push(row.path);
      byBucket.set(row.bucket, list);
    }

    // 2. Remove those photos, in small batches.
    for (const [bucket, paths] of byBucket) {
      for (let i = 0; i < paths.length; i += REMOVE_BATCH) {
        const removed = await fetch(`${url}/storage/v1/object/${encodeURIComponent(bucket)}`, {
          method: 'DELETE',
          headers: { ...adminHeaders, 'Content-Type': 'application/json' },
          body: JSON.stringify({ prefixes: paths.slice(i, i + REMOVE_BATCH) }),
          signal: AbortSignal.timeout(20000),
        });
        if (!removed.ok) {
          console.error(`delete_account_error storage_remove status=${removed.status}`);
          return json(502, { error: 'storage_remove_failed' });
        }
      }
    }

    // 3. Delete the auth user; the database cascades to every user table.
    const deleted = await fetch(`${url}/auth/v1/admin/users/${user.id}`, {
      method: 'DELETE',
      headers: adminHeaders,
      signal: AbortSignal.timeout(20000),
    });
    if (!deleted.ok) {
      console.error(`delete_account_error user_delete status=${deleted.status}`);
      return json(502, { error: 'delete_failed' });
    }
    console.log(`delete_account_ok files=${rows.length}`);
    return json(200, { deleted: true });
  } catch (error) {
    const name = error instanceof Error ? error.name : 'UnknownError';
    console.error(`delete_account_error ${name}`);
    return json(503, { error: 'service_unavailable' });
  }
}

if (typeof Deno !== 'undefined') Deno.serve(handler);
