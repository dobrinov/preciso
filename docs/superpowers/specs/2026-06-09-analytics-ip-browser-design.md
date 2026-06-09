# Analytics: record IP + browser, and use them for uniqueness

## Goal

Record each visitor's IP address and browser (user-agent) on analytics events,
display them in the admin dashboard, and identify a unique visitor by the
combination of **IP + browser + cookie** (instead of the cookie `sid` alone).
Country lookup is deliberately out of scope for now.

## Background

`Event` rows are written by `ApplicationController#track` (pageviews) and the order
event in `CheckoutController#create`; both are already suppressed when an admin is
signed in. Uniqueness today is `distinct.count(:sid)` in `Event.summary` and
`Event.daily`, where `sid` is a per-browser cookie set by `analytics_sid`. The
dashboard's "Recent activity" list renders `@recent` rows
(`app/views/admin/analytics/index.html.erb`).

## Data model

Add to `events`: `ip` (string), `user_agent` (string). Both nullable (older rows and
non-request contexts have neither).

## Capture

In `ApplicationController`:

```ruby
def client_ip
  request.headers["Fly-Client-IP"].presence || request.remote_ip
end
```

Fly's proxy sets `Fly-Client-IP` to the real client IP; `remote_ip` is the
dev/local/test fallback. `track` adds `ip: client_ip, user_agent: request.user_agent`
to its `Event.create!`. `CheckoutController#create` adds the same two to the order
`Event.create!`. (Both remain guarded by `admin_signed_in?`.)

## Unique visitor = IP + browser + cookie

On `Event`:

```ruby
VISITOR_KEY = Arel.sql("COALESCE(ip,'') || '~' || COALESCE(user_agent,'') || '~' || COALESCE(sid,'')")
```

`summary` and `daily` change `distinct.count(:sid)` →
`distinct.count(Event::VISITOR_KEY)`, producing `COUNT(DISTINCT (…concat…))` over the
three fields. `COALESCE` keeps pre-existing events (no ip/ua) counting by their `sid`,
so historical numbers don't break.

## Display

In `app/helpers/analytics_helper.rb`, a `browser_label(ua)` helper (regex, no gem)
returns a readable "Browser · OS" (e.g. "Chrome · macOS", "Safari · iOS"). Browser
detection order matters because UAs overlap: Edge (`Edg`) and Opera (`OPR|Opera`)
before Chrome, Chrome before Safari; else "Other"; blank → "Unknown". OS: iOS,
Android, macOS, Windows, Linux, else omitted.

In the "Recent activity" rows (`admin/analytics/index.html.erb`), add a muted subline
under the event text showing `"<ip> · <browser_label(user_agent)>"` (only the IP/
browser parts that are present), styled inline (`font-size:11px;color:var(--faint)`).
The IP is a link to an IP-geolocation lookup site —
`https://ipinfo.io/<ip>` — opened in a new tab (`target="_blank"`,
`rel="noopener"`), so the admin can see the location on demand without a bundled
GeoIP database.

## Files

- Migration: `events` + `ip:string` + `user_agent:string`.
- `app/controllers/application_controller.rb` — `client_ip` helper; ip/user_agent in `track`.
- `app/controllers/checkout_controller.rb` — ip/user_agent on the order event.
- `app/models/event.rb` — `VISITOR_KEY`; `summary` and `daily` use it.
- `app/helpers/analytics_helper.rb` — `browser_label`.
- `app/views/admin/analytics/index.html.erb` — IP + browser subline in recent rows.

## Out of scope

- Country / GeoIP (deferred).
- IP anonymization / retention policy (storing full IPs as requested; PII note only).
- Bot filtering, per-browser/per-IP breakdown panels.

## Privacy note

Raw IPs are personal data (GDPR; EU studio). Acceptable for an internal admin-only
dashboard; if compliance is needed later, add a retention window or truncate the last
octet. Not implemented here.

## Verification

No automated suite. Verify with `bin/rubocop` and an `ActionDispatch::Integration::Session`
(test env):

1. A pageview (anonymous) records `ip` and `user_agent` (set a custom UA + check
   `request.remote_ip` fallback locally).
2. `summary`/`daily` count unique visitors by the (ip, user_agent, sid) tuple: two
   visits with the same sid but different IPs count as 2; identical ip+ua+sid counts
   as 1.
3. Pre-existing rows (nil ip/ua) still count (by sid) via COALESCE.
4. `browser_label` returns expected labels for sample Chrome/Safari/Edge/Firefox/iOS
   user-agents.
5. The dashboard "Recent activity" rows show the IP + browser subline.
