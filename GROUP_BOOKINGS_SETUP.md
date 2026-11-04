# ROAD TRIP 2027 — Group Flights without email sign-in

Everyone can see each other's **flight schedules** in a private group and add outbound, return and connecting flights. A flight confirmation is optional and is visible only to the anonymous session that created it.

**User experience:** Each person opens https://mottikallus-sys.github.io/rome-2027-guide/my-trip.html, enters their name/couple and the shared private group code once, then uses the shared board. No email, individual approvals, or visible account login.

## Two setup steps for the organizer

1. **Enable anonymous authentication.** In Supabase Dashboard → Authentication → Sign In / Providers → User Signups, turn on **Allow anonymous sign-ins** and save. This is the automatic anonymous authentication under the hood; it is not the same as opening the flight database to the public.
2. **Create one private group code.** In Supabase Dashboard → SQL Editor → New query, open [GUEST_CODE_SETUP.sql](./GUEST_CODE_SETUP.sql), paste its full contents, then Run. The result row contains your unique **private_group_code** (20 random characters). Copy the code into a private note. Do not put the code in GitHub, public chats, photos, or browser config.

Afterward, open the Group Flights page, enter a couple name and the code. It will create a guest session automatically. Share the *page link* and *code privately* with the group; they can enter their own flights and see everyone's itineraries. Existing SQL flight tables and their RLS policies remain in place.

## Security and limits
- Sharing the group code means sharing access. Anyone who knows the code can join, see flight times, and add their own entries. Only give it to your travel group.
- The Supabase database and group access logic enforce access on the server. The group code never appears in public GitHub code or browser config.
- Flight confirmation codes are stored in `trip_flight_confirmations`, accessible only to the creating session under the database's RLS policies. They do not appear on the group-wide board.
- **Anonymous sessions are linked to the browser/device.** If somebody clears browser storage, switches device, uses private browsing, or signs out, they may lose the ability to edit/delete flights entered earlier and to retrieve their own confirmation codes. They can rejoin with the group code but will be a new member. For this reason, avoid storing sensitive real confirmation codes and retain original airline confirmations elsewhere.
- The group can refresh to see new entries. True live flight status is not integrated; FlightAware tracking links open separately.
- For revoking a leaked code, run `select public.roadtrip_rotate_code();` in the private SQL Editor, copy the new code, and distribute it securely. **Rotating the code does not revoke members who already joined.** To revoke members, remove their rows in `trip_members` using the admin dashboard (and review owned records separately).
- This mode favors convenience over verified traveler identity. Users can choose any display name and the same group code works for everyone. If secure identity recovery or strict audit is required, switch back to email accounts.
- The SQL file `SUPABASE_SETUP.sql` was run previously to create `trip_members`, `trip_flights`, and `trip_flight_confirmations` with RLS. Do **not** remove those tables.
