# delete-account Edge Function

Lets a signed-in user permanently delete their own account from
Settings > Privacy & Data. The app asks for the password first, then calls this
function with the user's session token.

What it does, in order:

1. Checks the caller's token with Supabase Auth (registered, non-anonymous user).
2. Requires the body `{"confirm":"DELETE"}`.
3. Lists the account's stored photos with `public.account_storage_paths`
   (post photos, group photos, and avatars/photos of groups the user owns) and
   removes them from Storage. If this fails, nothing else is deleted.
4. Deletes the auth user. Every user table uses `ON DELETE CASCADE`, so the
   database rows go with it. Groups the user owns are deleted too.

## Setup (once, on the REAL project)

1. SQL Editor: run `supabase/account_deletion.sql`.
2. Edge Functions > Deploy a new function > Via Editor. Name it
   `delete-account` and paste this folder's `index.ts`.
3. Turn OFF "Verify JWT with legacy secret" for this function (same as the
   coach function). The function checks the token itself.
4. No new secrets are needed. Supabase supplies `SUPABASE_URL` and
   `SUPABASE_SERVICE_ROLE_KEY`.

## Safe test

Create a throwaway account in the app, post one photo, then delete it from
Privacy & Data. In Authentication > Users the account must be gone, and in
Storage the photo must be gone. Logs show `delete_account_ok files=<n>`.
Never test deletion with your real account.
