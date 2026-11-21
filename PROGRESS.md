# FindMedicine — Progress

## Milestone 1: Foundation ✅
- [x] Vite + React + TS scaffold
- [x] Brand config (`src/config/brand.ts`) — single source of truth
- [x] Tailwind v4 design system (custom CSS tokens, Inter + Plus Jakarta Sans)
- [x] UI components: Button, Card, Badge, Input, Skeleton, EmptyState
- [x] .gitignore, .env.example
- [x] Supabase schema migrations (`supabase/migrations/00001_schema.sql`)
  - [x] All tables with RLS
  - [x] `place_order` SECURITY DEFINER function
  - [x] `nearby_stores` and `stores_for_pincode` RPC
  - [x] Status transition trigger
  - [x] Stock restoration trigger
  - [x] pg_cron order expiry
  - [x] Realtime publication
- [x] Seed data: 18 medicines, 4 stores (Shirpur area), demo users
- [x] Auth: email+password signup with role selection, login, logout
- [x] Protected routes, role-based redirects

## Milestone 2: Customer Flow ✅
- [x] Medicine catalog (search, Rx chip, add to cart)
- [x] Cart (quantity stepper, Rx warning)
- [x] Fulfilment choice page (Pickup / Delivery + address) — radio inputs
- [x] Store selection via `nearby_stores` RPC (pickup) and `stores_for_pincode` RPC (delivery)
  - [x] Partial stock warning with "Remove missing & select"
  - [x] Explicit "Select" button per store row
  - [x] No map, no pins, no geocoding
  - [x] Geolocation API with fallback
- [x] Prescription upload page (delivery + Rx items → mandatory)
- [x] Review order page (Rx advisory for pickup)
- [x] `place_order` RPC call (server-enforced prices, stock, Rx check)
- [x] Order tracking with realtime status updates
- [x] Orders list page
- [x] Cancel pending order

## Milestone 3: Store Owner Flow ✅
- [x] Store dashboard with live order list
- [x] Realtime order notifications (Supabase Realtime)
- [x] Sound + browser Notification API + "Enable alerts" button
- [x] "Keep this tab open" banner
- [x] Order detail: items, customer name/phone, address
- [x] Prescription viewer (signed URL, image + PDF)
- [x] Actions: Accept / Reject (with reason + quick reasons)
- [x] Mark ready / out for delivery
- [x] Complete with handover code
- [x] Inventory management (price + stock editable per row)
- [x] Store setup with geolocation button

## Milestone 4: Polish & Testing ✅
- [x] Order expiry via pg_cron
- [x] Stock restoration on reject/cancel/expire
- [x] Footer on every page
- [x] TypeScript strict mode — zero errors
- [x] Production build passes
- [x] Playwright e2e tests — 7 scenarios (`tests/e2e/findmedicine.spec.ts`)
- [x] `playwright.config.ts` with auto-webserver start
- [ ] `.env` filled with real anon key → app starts
- [ ] Migrations applied to Supabase (SQL in `supabase/migrations/00001_schema.sql`)
- [ ] Seed applied (`supabase/seed.sql`) — demo users may need Dashboard creation
- [ ] Final commit + push

## Notes
- Tailwind v4 installed (uses `@theme` CSS variables, no `tailwind.config.js`)
- Database types in `src/types/database.ts` (manual until Supabase CLI generates them)
- FulfilmentPage uses radio `<input>` elements inside `<label>` wrappers for accessibility + Playwright compatibility
- StoreSelectionPage: each store row has an explicit "Select" button (Playwright-friendly)
- CartPage checkout button label: "Checkout"
- Store UUIDs in seed: `c0000000-0000-0000-0000-00000000000{1-4}`
- Medicine UUIDs: `00000000-0000-0000-0000-{001-012,00a-012}`
- Demo accounts password: `Test1234!`
