# IkeepAnEye — Product Requirements Document

## 1. Product Overview

**IkeepAnEye** is an iOS e-commerce app that lets users photograph their own eye and order a custom photo pendant with that image. The experience combines on-device biometric capture with a standard e-commerce checkout, producing a uniquely personal piece of jewellery.

---

## 2. Users

| Persona | Description |
|---|---|
| **Customer** | iOS user who discovers the product, captures their eye, and places an order |
| **Admin** | Internal team member who reviews orders, manages the product catalogue, and fulfils shipments via the web admin panel |

---

## 3. Core User Journey (Customer)

```
Browse catalogue
  → View product detail
    → Capture / select eye photo
      → Review composite preview
        → Add to cart
          → Enter shipping address
            → Pay via Stripe
              → Receive order confirmation
                → Track order in Order History
```

### 3.1 Catalogue

- Grid of products loaded in real-time from Firestore (`products` collection).
- Each product has a name, description, price, and one or more images (one marked as main).
- Tapping a product opens the detail view.

### 3.2 Eye Capture

- User opens the camera from the product detail view.
- An on-device Vision pipeline detects the eye in real time and draws a live overlay.
- User can switch between front and rear cameras.
- After capture, user reviews the crop and can adjust it.
- The eye photo is **never uploaded** until the user explicitly taps "Use Photo".
- After confirmation the photo is uploaded to Firebase Storage and a metadata document is written to the `irisPhotos` sub-collection under the user.

### 3.3 Pendant Preview

- A composite image is generated client-side showing the product with the eye inlaid.
- User can browse other eye photos from their library or capture a new one.

### 3.4 Cart

- Supports multiple items (different products, different eye photos).
- Each item holds: product, eye photo if selected by yser, and shipping address.
- Shipping address can be pre-filled from the user's saved profile address.

### 3.5 Checkout & Payment

- Cart items are persisted as individual `orders` documents in Firestore with status `pending_payment`.
- A `createPaymentIntent` Cloud Function is called for each order, returning a Stripe client secret.
- Payment is handled by Stripe's native `PaymentSheet` (card, Apple Pay).
- On payment success, a Stripe webhook triggers the `handleStripeWebhook` Cloud Function, which marks the order `paid`.
- If payment fails, the user can retry from the same screen (a fresh `PaymentSheet` is loaded automatically).

### 3.6 Order History

- All orders are listed newest-first.
- Each order detail screen shows:
  - Product thumbnail + name + price
  - Eye photo used for engraving (fetched from Storage)
  - Order ID, date, and status
  - Full pricing breakdown (subtotal, shipping, tax, total)
  - Shipping address
  - Tracking number and carrier (once shipped)
  - **"Complete Payment" button** — visible only for `pending_payment` orders, allowing retry from history

### 3.7 User Profile

- Email/password authentication (Firebase Auth).
- Saved shipping address (pre-fills checkout).
- Eye photo library: view, activate/deactivate, and delete photos.
  - Deletion calls a `deleteEyePhoto` Cloud Function that hard-deletes from Storage and Firestore.

---

## 4. Admin Web Panel

React + Vite SPA at `/web-admin`, authenticated via Firebase Auth.

### 4.1 Orders

- Tabbed list filtered by status (All / Paid / In Production / Shipped / Delivered / Refunded).
- Search by order ID, product name, or customer name.
- Each row shows: order ID, customer name, **product thumbnail**, **eye photo thumbnail** (clickable → full-size modal with Print/Download actions), total, status badge, date.
- Order detail page: full order info + status change controls.

### 4.2 Products

- List of all products with main image, name, price, and stock status.
- Create / edit product: name, description, price, images.
- Image management per product: upload images to Storage, set one as main, delete images.
- Save-first workflow: product must be saved before images can be uploaded.

### 4.3 Customers

- Customer list with search.
- Customer detail: profile info, saved eye photos, order history, session-grouped analytics event timeline.

### 4.4 Analytics

- `userEvents` Firestore collection records 8 events per session:
  `catalog_viewed`, `product_viewed`, `eye_capture_started`, `eye_capture_completed`,
  `cart_viewed`, `checkout_started`, `payment_completed`, `order_history_viewed`
- Events are client-only writes (admin-only read); displayed on the customer detail page.

---

## 5. Cloud Functions (TypeScript, Node 20)

| Function | Trigger | Responsibility |
|---|---|---|
| `createPaymentIntent` | HTTPS callable | Creates/retrieves Stripe customer + payment intent; returns client secret |
| `handleStripeWebhook` | HTTPS | Verifies webhook signature; marks order `paid` on `payment_intent.succeeded` |
| `deleteEyePhoto` | HTTPS callable | Deletes iris photo from Storage + Firestore |
| `onOrderCreated` | Firestore trigger | Sends order confirmation email (stub — needs SendGrid/Resend) |

---

## 6. Data Model (Firestore)

```
users/{uid}
  ├── irisPhotos/{photoId}
  └── (profile fields: email, displayName, shippingAddress, stripeCustomerId*)

orders/{orderId}
  ├── userId, status, productId
  ├── productSnapshot { name, priceInCents, imageURL }
  ├── eyePhotoId?, eyePhotoStoragePath?
  ├── previewCompositeStoragePath?
  ├── shipping (Address)
  ├── pricing { subtotalCents, shippingCents, taxCents, totalCents }
  ├── payment* { stripePaymentIntentId, stripeChargeId, status, paidAt }
  └── fulfillment? { trackingNumber, carrier, shippedAt }

products/{productId}
  ├── name, description, priceInCents, isActive
  └── images [{ storagePath, downloadURL, isMain }]

userEvents/{eventId}
  └── userId, sessionId, event, timestamp, metadata
```

`*` written by Cloud Functions only (blocked for client writes in Firestore rules).

---

## 7. Order Statuses

| Status | Meaning |
|---|---|
| `pending_payment` | Order created; payment not yet confirmed |
| `paid` | Stripe webhook confirmed payment |
| `in_production` | Admin has started engraving |
| `shipped` | Tracking number added |
| `delivered` | Confirmed delivered |
| `cancelled` | Cancelled before production |
| `refunded` | Payment refunded |

---

## 8. Non-Functional Requirements

| Requirement | Approach |
|---|---|
| Privacy | Eye photos stored in authenticated Firebase Storage; never public; client never uploads until user confirms |
| Payment security | No card data touches the app; Stripe handles everything; secret key only in Cloud Function environment |
| Offline tolerance | Firestore real-time listeners cache locally; product catalogue available if previously loaded |
| iOS version | iOS 16.0+ |
| Device | Personal Team — runs on personal device; App Store submission requires paid Apple Developer account |

---

## 9. Known Gaps (Pre-Production)

| Gap | Detail |
|---|---|
| Email notifications | `emailService.ts` is a stub — needs SendGrid or Resend integration |
| Shipping cost | Hardcoded at $9.99 in `CartViewModel`, `OrderService`, and `createPaymentIntent` CF |
| Tax rate | Hardcoded at 8% in same files |
| Apple Pay merchant ID | Hardcoded as `merchant.com.ikeepaneye` in `StripeService.swift` — must match Stripe/Apple setup |
| Order fulfillment | Status stays `paid` until manually updated in Firestore console |
| App Store | Cannot submit without upgrading to paid Apple Developer account ($99/yr) |
| Sign in with Apple | Removed — requires paid developer account |
