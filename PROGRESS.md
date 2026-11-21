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
- [x] `.env` filled with real anon key → app starts
- [x] Migrations applied to Supabase
- [x] Demo users created and linked to stores
- [x] Playwright e2e tests — 7 scenarios (`tests/e2e/findmedicine.spec.ts`)
- [x] `playwright.config.ts` with auto-webserver start

## Verification Results (20/20 PASS)
1. ✅ Customer login
2. ✅ Medicines loaded (18 items)
3. ✅ Nearby stores (haversine, 4 stores within 10km)
4. ✅ Place pickup order (atomic, stock deducted, handover code generated)
5. ✅ Customer sees own order (RLS)
6. ✅ Store owner login
7. ✅ Store owner sees store orders (RLS)
8. ✅ Accept order (pending → accepted)
9. ✅ Mark ready (accepted → ready)
10. ✅ Complete order (ready → completed)
11. ✅ Stock deducted (200 → 198 after qty 2)
12. ✅ Notification created for store owner
13. ✅ Invalid status transition blocked (completed → accepted)
14. ✅ Delivery+Rx without prescription rejected by DB
15. ✅ Delivery+Rx with prescription succeeds
16. ✅ Stock restored on reject (29 → 30)
17. ✅ Order status = rejected after rejection
18. ✅ Reject reason stored ("Invalid prescription")
19. ✅ Pincode store lookup (3 delivery stores for 425405)
20. ✅ Role immutability enforced (customer → store_owner blocked)
