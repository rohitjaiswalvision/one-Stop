# Multi-provider service checkout — backend contract

**Status:** blocked on backend. No app code has been changed.

## Goal

A customer books a plumber from **Sharma Plumbing** and an electrician from **Kumar Electricals** in a single cart, and **pays once**.

## Why the app cannot do this alone

Today the cart is forced to a single store, and for good reason — the order pipeline has one `store_id` end to end:

| Constraint | Where |
|---|---|
| Cart rejects a second store ("reset your cart") | `cart_service.dart:315` `existAnotherStoreItem` |
| Checkout takes the store from cart item **0** | `checkout_screen.dart:151` `initCheckoutData(_cartList![0]!.item!.storeId)` |
| An order body carries **one** `store_id` | `place_order_body_model.dart:244` |
| `/order/place` returns **one** `order_id` | `checkout_repository.dart:62` |
| Gateway URL is keyed to one order | `payment_screen.dart:50` `payment-mobile?order_id=…` |
| Success/fail callbacks carry one order | `order_service.dart:136-200` |

Lifting only the cart restriction would post **both** providers' bookings to Sharma Plumbing, validate Kumar's time slot against Sharma's opening hours, and pay Sharma for both. That is a money bug, not a UI bug.

Looping `/order/place` per provider is easy. **Paying for N orders is not** — every step of the payment flow takes exactly one `order_id`. Chaining two gateway sessions would leave one order paid and one unpaid if the customer abandons the second, and there is no compensation/cancel logic anywhere in the codebase.

Note this bites *services specifically*: COD is currently hard-disabled for everyone (`checkout_screen.dart:874` — `_checkCODActive` just returns `false`, real logic commented out), so service bookings are **digital-payment-only**. The one method that can't do multi-order is the only one services can use.

---

## What the backend needs to provide

### 1. Mixed-store cart

`/customer/cart/add` must accept items from several stores in one customer cart. The app will stop sending the "reset cart" prompt for the service module. Confirm the server does not itself assume a single store per cart.

### 2. Group order placement

A new endpoint that accepts N orders and returns **one payable group id**:

```
POST /api/v1/customer/order/place-group

{
  "payment_method": "digital_payment",
  "orders": [
    {
      "store_id": 12,
      "order_amount": 200,
      "tax_amount": 18,
      "coupon_code": null,
      "cart": [ { "item_id": 501, "price": "20", "quantity": 10, "model": "Item", ... } ],
      "service_bookings": [
        { "item_id": 501, "service_date": "2026-07-20", "start_time": "10:30", "location_type": "home" }
      ],
      "customer_address_id": 77,
      "address": "...", "latitude": "...", "longitude": "..."
    },
    { "store_id": 47, "...": "..." }
  ]
}
```

Each element is the **existing** `PlaceOrderBodyModel` shape (see `place_order_body_model.dart`), so per-store `store_id`, `order_amount`, `tax_amount`, `coupon_code`, `cart[]` and `service_bookings[]` are all already defined. Nothing new to model per order.

**Response:**

```json
{ "group_id": 991, "order_ids": [55, 56], "total_amount": 700, "message": "..." }
```

**Must be atomic.** Either every order is created or none is. A partial group (one booking created, one slot rejected) leaves the app with no way to recover — see the existing `service_slot` 403 handling in `checkout_controller.dart:1046`, which assumes a single order it can retry.

Slot-conflict and location-type rejections must still be reported per item so the app can point the customer at the offending booking:

```json
{ "errors": [ { "code": "service_slot", "item_id": 501, "message": "..." } ] }
```

### 3. Group payment

The gateway must be payable by group, not by order:

```
GET /payment-mobile?group_id=991&customer_id=…&payment_method=…&payment_platform=app&callback=…
```

`payment-success` / `payment-fail` / `payment-cancel` should carry `group_id`, and settling the group must mark **all** its orders paid. Per-provider payouts stay a backend concern; the customer sees one transaction.

If a `group_id` is genuinely impossible, the fallback is to keep one `order_id` as the payable "parent" and have the backend settle its siblings — but the app must still receive a single id to pay.

### 4. Vendor panel

Each provider must see **only their own** order from the group. Worth confirming, since today a store never receives an order containing another store's items.

---

## App work, once the contract is agreed

Roughly, and in this order:

1. **Cart** — skip `existAnotherStoreItem` for the service module (4 call sites: `item_details_screen.dart`, `details_web_view_widget.dart`, `item_bottom_sheet.dart`, `square_feet_bottom_sheet.dart`); group `cart_screen.dart`'s flat `ListView` by `item.storeId` with a provider header per group. Note `cart_screen.dart` currently reads `cartList[0].item!.storeId` in several places (lines 94-95, 275-280, 295) — all need to become per-group.
2. **Checkout** — the real refactor. `CheckoutController` holds `_store`, `_timeSlots`, `_orderTax`, `_extraCharge` and `distance` as **single values**; they must become per-store (keyed by `storeId`) so each provider gets its own fees, tax and slot validation. Render one checkout section per provider.
3. **Placement** — replace the single `PlaceOrderBodyModel` build (`checkout_screen.dart:683-786`) with one body per provider, posted to `place-group`.
4. **Payment** — `PaymentScreen` / `getPaymentRoute` / `paymentRedirect` take a `group_id` instead of an `order_id`. Reset the `_hasRedirected` static in `order_service.dart:23` between sessions.
5. **Success screen** — takes a group, lists the resulting orders.

Step 2 is the bulk of it. Steps 3-5 are mechanical once the endpoint exists.

## Open questions for the backend team

- **Coupons** are store-scoped today. In a group, does a coupon apply to one provider's order, or is there a group-level coupon? The app currently sends a single `coupon_code`.
- **Minimum order amount** is per store. Enforced per order in the group, or against the group total?
- Is there a cap on providers per group?
