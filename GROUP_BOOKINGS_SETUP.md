# ROAD TRIP 2027 — make everyone's flights appear together

## What's already built
The separate **My Trip / Group Flights** page at
https://mottikallus-sys.github.io/rome-2027-guide/my-trip.html
allows approved travelers to sign in with an email magic link, add outbound/return/connection flights, and see all group flights across phones. Flight cards are grouped by traveler/couple; an all-group chronological board shows dates, flight numbers and airports.

Flight **booking references** are optional and stored in a separate table. Only the booking owner can read their code; group members can see the flight schedule but not confirmation codes.

## Important: connection still required
The GitHub site has no configured shared database yet. **Do not collect real flight confirmation codes until your Supabase project is configured, and your login/row-level security policies have been verified.** When not connected, the page shows a setup message and does **not** pretend bookings are synchronized.

1. Create a Supabase project under your account at https://supabase.com/ .
2. In Supabase **SQL Editor**, run `SUPABASE_SETUP.sql` from this repository. Verify it ran without errors. This creates `trip_members`, `trip_flights`, and `trip_flight_confirmations` and their RLS policies.
3. In **Authentication → Providers**, enable email magic-link/OTP sign-in. In **Authentication → URL Configuration**, add the exact redirect URL:
   `https://mottikallus-sys.github.io/rome-2027-guide/my-trip.html`
4. Open **Project Settings → API** (or **Connect** in newer Supabase UI). Copy the **Project URL** and the browser-safe **publishable** key (or legacy `anon` key) to `trip-config.js`. NEVER put the service role/secret key in GitHub.
5. Open the web page and sign in. The page will show your verified Supabase auth **User ID** while membership is pending. In the private Supabase SQL Editor, approve it:
   ```sql
   insert into public.trip_members(user_id,display_name)
   values ('THE_SIGNED_IN_USER_UUID','Organizer')
   on conflict(user_id) do update set display_name=excluded.display_name;
   ```
6. Invite the other travelers **by sharing the My Trip URL**. Each uses their own email sign-in link; after they log in, they privately share their user ID with you. You approve each verified ID in the SQL Editor in the same way.
7. Everyone can now add their own flights. Press **Refresh flights** to view new entries added by others. Group schedules are visible to all approved members; confirmation numbers are only shown to the person who entered them.

## Privacy and limitations
- Only approved members can read group flight schedules. Membership isn't available to the general public.
- Each member can delete their own flight; they can't modify someone else's.
- Real confirmation codes aren't required for the group board; preferably add only flight schedule data while first testing.
- **This is not airline-reservation lookup.** A booking reference by itself doesn't fetch itinerary details. Travelers must enter the flight number, date, and airports.
- The FlightAware button opens external flight tracking; flight status is not streamed into the app.
- GitHub Pages serves public code, not private flight data. Supabase handles authentication and access-controlled storage.
- The old `trip_bookings` table, if it was created in a prior setup, is not used by the new flights-only page. Review and remove it separately after backing up any data you wish to keep.
- If an authorized member opens a private reference, the airline may allow reservation changes. Do not share booking numbers in the group chat.
