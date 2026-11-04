# ROAD TRIP 2027 — live flight lookup setup

## What is implemented
The Group Flights page (`my-trip.html`) has **Look Up Flight** for entry by flight number and date and **Check flight status** on each saved flight. A private Supabase Edge Function (`supabase/functions/flight-lookup/index.ts`) calls the AeroDataBox flight status API through RapidAPI.

The Edge Function verifies the caller's Supabase anonymous-auth session and membership in `trip_members` before calling the provider. The paid API key never belongs in GitHub, the browser, or `trip-config.js`.

**Not live until configured and deployed.** The GitHub Pages app alone cannot call the private provider without an Edge Function and an AeroDataBox subscription.

## Three steps to activate

1. **Get a provider subscription:** Register for AeroDataBox on RapidAPI:
   https://rapidapi.com/aedbx-aedbx/api/aerodatabox
   Choose a free tier, if offered, or another suitable plan, review limits and terms. Copy the **X-RapidAPI-Key** privately, do not paste it into ChatGPT or GitHub.

2. **Set the secret in Supabase:** In your existing Supabase project open **Edge Functions → Secrets**. Add:
   - Name: `AERODATABOX_RAPIDAPI_KEY`
   - Value: your own RapidAPI key.
   Save. Never use the Supabase secret/service_role key here.

3. **Deploy the Edge Function:** In Supabase **Edge Functions → Deploy a new function → Via Editor**.
   - Function name: `flight-lookup`
   - Open [supabase/functions/flight-lookup/index.ts](./supabase/functions/flight-lookup/index.ts) in GitHub and paste its full contents into the Edge Function editor.
   - Deploy the function. Leave JWT verification enabled, since only joined group members should call it.
   - Confirm the function is named exactly `flight-lookup`.

Supabase docs for [Dashboard deployment](https://supabase.com/docs/guides/functions/quickstart-dashboard) and [Secrets](https://supabase.com/docs/guides/functions/secrets).

## How to test
- Open https://mottikallus-sys.github.io/rome-2027-guide/my-trip.html
- Enter your private group code if the browser hasn't joined yet.
- Click **+ Add flight**; fill in flight number and **departure date** (airport-local date).
- Click **Look Up Flight**. If a matching flight exists, it displays source, status, airports, scheduled times and updated times when available. Click **Fill form with these details** to use the information.
- Save the flight. On existing flight cards, **Check flight status** can query again.
- If you see “Provider connection not active yet”, check Edge Function deployment, key, and subscription.
- Provider search may return multiple codeshare/leg matches; verify the correct one before saving.

## Caveats
- Availability varies by airport and date. Distant future flights may only have scheduled details; some flights are not in coverage and some terminals/gates may not be known yet.
- A flight number + date cannot fetch passenger names, ticket confirmation codes or an airline booking record.
- The provider may charge a quota unit for each query; check RapidAPI plan limits before sharing broadly. Do not automatically refresh in the background.
- The status screen displays data from the provider, not official airline notices. Confirm changes with the airline.
- The Edge Function enforces Supabase member authentication. Group access codes should remain private. The function's source code can be public because **the key is held in Supabase secrets**.
- Additional live automatic notifications require separate background jobs and provider alerts (not implemented).
