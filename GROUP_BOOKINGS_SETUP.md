# ROAD TRIP 2027 — group booking app

The `my-trip.html` page is a separate app-like screen. The entire invited group **shares all reservation details**, including confirmation numbers, names, flights, hotels, and dates.

## Current mode
The page initially shows **fictional examples** only. Real reservations and authentication remain disabled until the database is configured. There are no genuine user accounts, bookings, or group invitations yet.

## Enable private shared trip data
1. Create a Supabase project under your own account.
2. Run `SUPABASE_SETUP.sql` in Supabase SQL Editor, then enable email OTP/magic-link login under Authentication.
3. In Authentication → URL Configuration, allow the exact redirect URL: https://mottikallus-sys.github.io/rome-2027-guide/my-trip.html
4. Copy the project URL and **publishable/anon** public browser key into `trip-config.js`. Do **not** use a service_role key or a database password.
5. Open the site and sign in yourself once by email link. The organizer must then add your verified user ID to `trip_members` through the Supabase dashboard.
6. Have each guest sign in via email link, verify their identity, then add their user ID to `trip_members`. No one can self-join by guessing the link.
7. Once invited, every member can read every other member's reservations, including confirmation codes. Owners can create and delete their own bookings.

## Security
- GitHub Pages is public. **Never put actual confirmation codes or passenger information in the repo.**
- A confirmation number together with passenger details can sometimes be used to access or change a reservation. Everyone must explicitly consent to sharing their booking references with the entire invited group.
- The Supabase row-level security policies enforce membership for every read; browser UI restrictions alone do not count.
- The UI takes flight details entered manually. A confirmation number on its own cannot reliably pull live details from an airline.
- This is not affiliated with TripIt or any airline.
