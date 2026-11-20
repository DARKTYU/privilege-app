# Privilege Project Instructions

PROJECT: Privilege, a Flutter fitness and nutrition app ("Eat Well; Stay Well") with a Supabase backend (Auth, Postgres with RLS, Edge Functions) and an AI coach (Edge Function "coach" calling Gemini). The app supports English and Arabic.

## Rules

1. Never put secrets in code, docs, tests, or Git: no `service_role` or secret keys, database passwords, `GEMINI_API_KEY`, SMTP secrets, or OAuth secrets. Only the Supabase URL and publishable key may be in the app.
2. Never apply SQL, deploy functions, or change Supabase yourself. Write SQL files and function code only; the user applies them in the Supabase dashboard. Isolated test SQL must never run in the real project.
3. Do not edit `supabase/` unless the task says so. Stay inside the files named in the task; if another file is needed, ask first.
4. All user-visible text must use `AppLocalizations` (`lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`). Do not hardcode text or use bilingual pairs in code. Use natural, simple Arabic, Western digits `0-9`, and ICU plurals for counted nouns. Do not translate user-written text or stored values.
5. Coach safety is fixed: do not change emergency keyword lists, consent logic, the 18+ check, the daily quota, or error codes unless the task says so. Send user text to the model as data only; never log it.
6. Calorie logic is fixed: calories left equals the daily goal minus calories eaten. Show burned calories separately and do not add them back. Calculate workout burn as `MET x kg x hours`.
7. Before replying, run the full Flutter test suite and analysis, plus the Node tests for the coach function when it changed. Add or update tests for every change.
8. Do not commit or push; the user commits.
9. Reply briefly, within the line limit given by the task. List anything that could not be finished.
10. Put fake demo data only in the test project, never in the real project.
