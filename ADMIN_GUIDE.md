# IkeepAnEye — Admin & Developer Guide

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [System Architecture](#2-system-architecture)
3. [Repository Structure](#3-repository-structure)
4. [Firebase: Emulator vs Production](#4-firebase-emulator-vs-production)
5. [Firebase Services & Configuration](#5-firebase-services--configuration)
6. [Security Rules](#6-security-rules)
7. [Cloud Functions Reference](#7-cloud-functions-reference)
8. [iOS App — User Experience](#8-ios-app--user-experience)
9. [Admin Web Panel](#9-admin-web-panel)
10. [Order Lifecycle](#10-order-lifecycle)
11. [Data Models](#11-data-models)
12. [Known Gaps & Pre-Production Checklist](#12-known-gaps--pre-production-checklist)

---

## 1. Product Overview

IkeepAnEye is an iOS e-commerce app for ordering custom eye pendants. A user photographs their eye, selects a pendant design from a catalog, and places an order. The pendant is then crafted and shipped.

**Key concept**: The eye photo is purely personal — it is captured on-device by Apple's Vision framework, never leaves the phone until the user explicitly taps "Use Photo", and is stored in a private Firebase Storage path accessible only to that user and admins.

---

## 2. System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  iOS App (SwiftUI)                                          │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌──────────┐  │
│  │ Catalog  │  │  Cart    │  │  Checkout │  │  Profile │  │
│  │ Grid/    │  │ CartStore│  │ Stripe    │  │ Orders / │  │
│  │ Detail   │  │ (global) │  │ PaySheet  │  │ EyePhot.│  │
│  └────┬─────┘  └────┬─────┘  └─────┬─────┘  └────┬─────┘  │
│       │             │              │              │         │
└───────┼─────────────┼──────────────┼──────────────┼─────────┘
        │             │              │              │
        ▼             ▼              ▼              ▼
┌─────────────────────────────────────────────────────────────┐
│  Firebase (Auth / Firestore / Storage / Functions)          │
│                                                             │
│  Collections:                                               │
│    products   users/{uid}   users/{uid}/eyePhotos          │
│    orders     admins        userEvents                       │
│                                                             │
│  Storage buckets:                                           │
│    users/{uid}/eye/{photoId}/original.jpg                  │
│    users/{uid}/eye/{photoId}/cropped.jpg                   │
│    products/{productId}/images/{filename}                   │
│    orders/{orderId}/preview.jpg                             │
└───────────────────────┬─────────────────────────────────────┘
                        │
        ┌───────────────┼──────────────────┐
        ▼               ▼                  ▼
┌───────────────┐  ┌──────────┐  ┌─────────────────┐
│  Web Admin    │  │  Stripe  │  │  Cloud Functions │
│  (React/Vite) │  │ (Payment)│  │  (TypeScript)    │
└───────────────┘  └──────────┘  └─────────────────┘
```

### How the pieces talk to each other

| From | To | How | When |
|---|---|---|---|
| iOS App | Firestore | Firebase SDK (real-time) | Product catalog, order creation, order history |
| iOS App | Firebase Storage | Firebase SDK | Eye photo upload/download |
| iOS App | Cloud Functions | Firebase Callable Functions | createPaymentIntent, deleteEyePhoto |
| iOS App | Stripe | StripePaymentSheet SDK | Payment UI, card collection |
| Stripe | Cloud Functions | HTTP webhook | Payment success/failure confirmation |
| Web Admin | Firestore | Firebase SDK (real-time) | Read/update orders, products, users |
| Web Admin | Firebase Storage | Firebase SDK | Eye photo viewing, product image upload |
| Web Admin | Cloud Functions | Firebase Callable Functions | refundOrder |
| Cloud Functions | Stripe | Stripe Node SDK | Create payment intent, issue refunds |
| Cloud Functions | Firestore | Firebase Admin SDK | Update order status, user records |
| Cloud Functions | Email (stub) | EmailService | Transactional emails (not yet implemented) |

---

## 3. Repository Structure

```
IkeepAnEye/
├── IkeepAnEye/                    # iOS app source (Swift)
│   ├── App/
│   │   ├── IkeepAnEyeApp.swift    # @main entry point
│   │   ├── AppDelegate.swift      # Firebase init + emulator routing
│   │   └── RootCoordinator.swift  # Auth state → correct view
│   ├── Models/
│   │   ├── Product.swift          # Product + ProductImage structs
│   │   ├── Order.swift            # Order + nested types
│   │   └── EyePhoto.swift        # Eye photo document model
│   ├── Services/
│   │   └── AnalyticsService.swift # User event tracking
│   ├── Core/
│   │   ├── Networking/
│   │   │   └── FunctionsClient.swift  # Typed wrapper for callable CFs
│   │   └── ...
│   └── Features/
│       ├── Auth/                  # Login / register views
│       ├── Catalog/               # Product grid + detail + pendant preview
│       ├── EyeCapture/           # Camera + crop/review flow
│       ├── Order/                 # Cart, checkout, confirmation
│       ├── OrderHistory/          # Order list + detail view
│       └── Profile/               # Eye photo management
│
├── functions/                     # Firebase Cloud Functions (TypeScript)
│   ├── src/
│   │   ├── index.ts               # Exports all functions
│   │   ├── config/
│   │   │   ├── firebase.ts        # Admin SDK init
│   │   │   └── stripe.ts          # Stripe factory + secret refs
│   │   ├── functions/
│   │   │   ├── auth/              # createUserRecord, deleteUserData
│   │   │   ├── payments/          # createPaymentIntent, handleStripeWebhook
│   │   │   ├── orders/            # onOrderCreated, onOrderStatusChanged, refundOrder
│   │   │   └── photos/            # deleteEyePhoto
│   │   ├── services/
│   │   │   └── emailService.ts    # Stub — needs SendGrid/Resend
│   │   ├── types/                 # Shared TypeScript interfaces
│   │   └── scripts/
│   │       └── seedProducts.ts    # One-time emulator seed script
│   └── lib/                       # Compiled output (auto-generated, gitignored)
│
├── web-admin/                     # Admin web panel (React + Vite)
│   ├── src/
│   │   ├── App.tsx                # Routes
│   │   ├── firebase.ts            # Firebase init + emulator routing
│   │   ├── pages/
│   │   │   ├── DashboardPage.tsx
│   │   │   ├── OrdersPage.tsx
│   │   │   ├── OrderDetailPage.tsx
│   │   │   ├── ProductsPage.tsx
│   │   │   ├── CustomersPage.tsx
│   │   │   └── CustomerDetailPage.tsx
│   │   ├── hooks/                 # useProducts, useCustomers, useUserEvents, ...
│   │   └── components/            # Layout, IrisPhotoModal, OrderStatusBadge
│   └── .env.local                 # Firebase config (gitignored)
│
├── firestore.rules                # Firestore security rules
├── storage.rules                  # Storage security rules
├── firestore.indexes.json         # Composite query indexes
├── firebase.json                  # Firebase project config + emulator ports
└── project.yml                    # XcodeGen spec (generates .xcodeproj)
```

---

## 4. Firebase: Emulator vs Production

This is the most important operational distinction to understand. **The same codebase runs against either local emulators or production Firebase**, controlled entirely by a single flag. No data ever crosses between them.

### What the emulator is

The Firebase Emulator Suite is a set of local processes that replicate Firebase services on your Mac. It stores data only in memory — it is wiped every time you stop and restart the emulators. It is used for development and testing only.

```
┌─────────────────────────────────────────────┐
│  Your Mac (Emulator)                        │
│                                             │
│  Auth       → localhost:9099                │
│  Firestore  → localhost:8080                │
│  Storage    → localhost:9199                │
│  Functions  → localhost:5001                │
│  UI         → localhost:4000  ← browser UI  │
└─────────────────────────────────────────────┘
```

### What production is

Firebase's actual cloud infrastructure (Google's servers). Data persists permanently. Real users, real orders, real payments.

### The single flag that controls which environment is used

#### iOS App — `AppDelegate.swift`

```swift
// AppDelegate.swift
if ProcessInfo.processInfo.environment["USE_EMULATOR"] == "1" {
    Auth.auth().useEmulator(withHost: "localhost", port: 9099)

    let settings = FirestoreSettings()
    settings.host = "localhost:8080"
    settings.cacheSettings = MemoryCacheSettings()
    settings.isSSLEnabled = false
    Firestore.firestore().settings = settings

    Storage.storage().useEmulator(withHost: "localhost", port: 9199)
}
```

This runs at app launch. If `USE_EMULATOR` is not set (or not `"1"`), all three Firebase SDK instances connect to production with no code change needed.

**How to set it in Xcode:**
> Xcode → Edit Scheme → Run → Arguments tab → Environment Variables → add `USE_EMULATOR = 1`

The iOS `FunctionsClient` also checks this flag to route callable functions to the local emulator:

```swift
// FunctionsClient.swift
#if DEBUG
if ProcessInfo.processInfo.environment["USE_EMULATOR"] == "1" {
    functions.useEmulator(withHost: "127.0.0.1", port: 5001)
}
#endif
```

Note: this only applies in `DEBUG` builds. A release build always connects to production regardless of the flag.

#### Web Admin — `web-admin/src/firebase.ts`

```typescript
// firebase.ts
if (import.meta.env.VITE_USE_EMULATOR === "1") {
    connectAuthEmulator(auth, "http://localhost:9099", { disableWarnings: true });
    connectFirestoreEmulator(db, "localhost", 8080);
    connectStorageEmulator(storage, "localhost", 9199);
    connectFunctionsEmulator(functions, "localhost", 5001);
}
```

**How to set it for the web admin:**
Add to `web-admin/.env.local`:
```
VITE_USE_EMULATOR=1
```

#### Cloud Functions — `functions/.secret.local`

The functions themselves always run in the emulator process when you do `firebase emulators:start`. But Stripe secrets need to be available locally. Create this file (gitignored):

```
# functions/.secret.local
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

Without this file, calling `createPaymentIntent` or `refundOrder` from the emulator will fail with a missing-secret error.

### Environment comparison table

| Aspect | Emulator | Production |
|---|---|---|
| Flag | `USE_EMULATOR=1` | flag absent (or `0`) |
| Auth port | `localhost:9099` | Firebase cloud |
| Firestore port | `localhost:8080` | Firebase cloud |
| Storage port | `localhost:9199` | Firebase cloud |
| Functions port | `localhost:5001` | Firebase cloud |
| Data persistence | **In memory — wiped on restart** | Permanent |
| Firestore rules enforced | Yes (same rules file) | Yes |
| Storage rules enforced | Yes (same rules file) | Yes |
| Stripe keys | From `functions/.secret.local` | From Firebase Secret Manager |
| Cost | Free | Pay-per-use |
| Admin UI | `localhost:4000` | Firebase Console |
| Seed data needed | Yes — run seed script | No — real data exists |
| Real emails sent | No (email service is a stub anyway) | Yes (once email service is wired) |

### Starting the emulator

```bash
# Terminal 1 — start all emulators
firebase emulators:start

# Terminal 2 — seed product catalog (first time, or after wipe)
USE_EMULATOR=1 npx ts-node functions/src/scripts/seedProducts.ts
```

Then open `localhost:4000` in a browser to see the Emulator UI — you can browse Firestore documents, Storage files, and Auth users directly.

### Creating an admin user in the emulator

1. Open `localhost:4000` → Authentication → Add user (email + password)
2. Note the UID shown
3. Open Firestore → Create collection `admins` → Add document with that UID as the document ID → no fields needed

---

## 5. Firebase Services & Configuration

### Authentication

- **Method**: Email/password only
- **Sign-in with Apple**: Removed (requires paid Apple Developer Program — $99/year)
- **User record creation**: Automatic — a Cloud Function (`createUserRecord`) fires on every new signup and creates the Firestore user document + a Stripe customer

### Firestore Collections

| Collection | Description | Who writes |
|---|---|---|
| `products` | Pendant catalog | Admin web panel |
| `users/{uid}` | User profile + default shipping | App (safe fields only) + CF (stripeCustomerId) |
| `users/{uid}/eyePhotos` | Eye photo metadata | iOS app (on confirm) |
| `orders` | All orders | iOS app (create) + CF (payment/status) + Admin (status/fulfillment) |
| `admins` | Admin user UIDs | Manual (Bootstrap script / Firebase Console) |
| `userEvents` | Analytics funnel events | iOS app |

### Firebase Storage Paths

| Path | Contents | Access |
|---|---|---|
| `users/{uid}/eye/{photoId}/original.jpg` | Full-resolution eye photo | Owner + Admin only |
| `users/{uid}/eye/{photoId}/cropped.jpg` | Circular cropped eye | Owner + Admin only |
| `products/{productId}/images/{filename}` | Product catalog images | Public read, Admin write |
| `orders/{orderId}/preview.jpg` | Pendant composite preview | No direct access — signed URL via CF |

### Cloud Functions Deployment

```bash
cd functions
npm run build          # compile TypeScript → lib/
firebase deploy --only functions
```

Functions use **Node 20** runtime. Secrets (`STRIPE_SECRET_KEY`, etc.) are stored in **Firebase Secret Manager** — set them once:

```bash
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
firebase functions:secrets:set STRIPE_PUBLISHABLE_KEY
```

### Firestore Indexes

Three composite indexes are defined in `firestore.indexes.json` and must be deployed:

```bash
firebase deploy --only firestore:indexes
```

| Collection | Fields | Use |
|---|---|---|
| `products` | `isActive` ASC, `sortOrder` ASC | Catalog listing |
| `orders` | `userId` ASC, `createdAt` DESC | User order history |
| `orders` | `userId` ASC, `status` ASC, `createdAt` DESC | Filtered order history |

---

## 6. Security Rules

### Firestore — key rules summary

| Collection | Read | Write |
|---|---|---|
| `products` | Anyone (active only) or Admin (all) | Admin only |
| `users/{uid}` | Owner or Admin | Owner (safe fields); CF-only for `stripeCustomerId` |
| `users/{uid}/eyePhotos` | Owner or Admin | Owner (create only); CF-only for delete |
| `orders` | Owner or Admin | Owner (create + shipping update); CF for payment/status; Admin for all |
| `admins` | Owner or Admin | Never from client (Admin SDK only) |
| `userEvents` | Admin only | Owner (create own events only) |

### Storage — key rules summary

| Path | Read | Write |
|---|---|---|
| `users/{uid}/eye/**` | Owner or Admin | Owner (images under 10MB) |
| `products/**` | Public | Admin only |
| `orders/**` | No direct access | CF only (signed URLs served by CF) |

### Admin access

A user is considered an admin if a document exists at `/admins/{uid}` in Firestore. This check happens in both:
- **Web admin** (`useAdminAuth.ts`): checked on every page load
- **Cloud Functions** (`refundOrder.ts`): checked inside the function before any action

---

## 7. Cloud Functions Reference

### Auth Triggers

#### `createUserRecord`
**Trigger**: Firebase Auth `onCreate`
**What it does**:
1. Creates a Stripe customer (email, name)
2. Writes `users/{uid}` document with email, displayName, stripeCustomerId, timestamps
3. Gracefully continues if Stripe fails (stripeCustomerId will be null)

#### `deleteUserData`
**Trigger**: Firebase Auth `onDelete` (GDPR compliance)
**What it does**:
1. Deletes all eye Storage files under `users/{uid}/eye/`
2. Deletes all `users/{uid}/eyePhotos` documents
3. Anonymizes orders: sets `userId = "DELETED"`, clears eye and preview paths
4. Deletes the `users/{uid}` document

### Callable Functions (called directly from clients)

#### `createPaymentIntent`
**Called by**: iOS app (`StripeService.swift`)
**Auth required**: Yes — caller's UID must match `order.userId`
**What it does**:
1. Validates order exists and is in `pending_payment` status
2. **Re-verifies pricing server-side** (reads product price from Firestore — client price is not trusted)
3. Creates Stripe PaymentIntent
4. Creates Stripe ephemeral key for PaymentSheet
5. Returns `clientSecret`, `ephemeralKey`, `customerId`, `publishableKey` to iOS

#### `deleteEyePhoto`
**Called by**: iOS app (ManageEyePhotosView)
**Auth required**: Yes — scoped to caller's own photos
**What it does**:
1. Deletes `original.jpg` and `cropped.jpg` from Storage
2. Hard-deletes the Firestore document in `users/{uid}/eyePhotos/{photoId}`

#### `refundOrder`
**Called by**: Web admin (OrderDetailPage)
**Auth required**: Yes — must be in `admins` collection
**What it does**:
1. Validates order is in `paid` or `in_production` status
2. Issues full Stripe refund using `stripeChargeId`
3. Updates order: `status = "refunded"`, stores refund ID and timestamp

### Firestore Triggers

#### `onOrderCreated`
**Trigger**: New document in `orders`
**What it does**: Sends order acknowledgement email (stub — logs intent)

#### `onOrderStatusChanged`
**Trigger**: Order document update where status changed
**What it does**: Sends appropriate transactional email + push notification per status transition:
- `paid` → payment confirmation
- `in_production` → "your pendant is being crafted"
- `shipped` → shipping notification with tracking number
- `delivered` → delivery confirmation

### HTTP Endpoint

#### `handleStripeWebhook`
**URL**: `https://<region>-<project>.cloudfunctions.net/handleStripeWebhook`
**Called by**: Stripe (not by the app)
**What it does**:
- Verifies Stripe webhook signature (rejects unsigned events)
- `payment_intent.succeeded` → sets `status = "paid"`, writes payment details to order
- `payment_intent.payment_failed` → sets `payment.status = "failed"` on order

---

## 8. iOS App — User Experience

### App launch

```
App starts
    │
    ├── FirebaseApp.configure() runs in AppDelegate
    │   └── If USE_EMULATOR=1 → routes all SDK calls to localhost
    │
    └── RootCoordinator checks Firebase Auth state
            ├── Loading  → SplashView (eye icon)
            ├── Signed out → LandingView
            │       ├── "Sign In" → AuthView (email/password)
            │       └── "Create Account" → AuthView (register)
            └── Signed in → MainTabView
                    ├── Tab 1: Shop (CatalogGridView)
                    ├── Tab 2: Orders (OrderHistoryListView)
                    └── Tab 3: Profile (ProfileView + ManageEyePhotosView)
```

### Shopping flow

```
CatalogGridView
  (real-time Firestore listener on active products, sorted by sortOrder)
    │
    ▼
ProductDetailView
  ├── Image carousel (all product.images, main image first)
  ├── Material, chain details, description
  ├── Eye photo selector:
  │     ├── "None" — order without personalization
  │     ├── Stored eye photos (loaded from eyePhotos subcollection)
  │     └── "New" — opens camera full-screen
  ├── "Preview Pendant" → PendantPreviewView (if iris selected)
  └── "Add to Cart" → CartStore.add()
```

### Eye capture flow

```
CameraView (full-screen)
  ├── Live camera preview (front or rear — toggleable)
  ├── Oval guide overlay ("Position your eye inside the oval")
  ├── No camera? (simulator) → PhotosPicker fallback
  └── Capture button
        │
        ▼
CropReviewView
  ├── Apple Vision detects eye automatically
  ├── User can drag/resize the crop rectangle
  ├── "Use Photo" → crops image + saves to Firebase Storage
  │     ├── original.jpg → users/{uid}/eye/{photoId}/original.jpg
  │     └── cropped.jpg  → users/{uid}/eye/{photoId}/cropped.jpg
  │         (circular mask applied)
  └── Photo is never uploaded until "Use Photo" is tapped
```

### Checkout flow

```
CartView
  ├── Item list (swipe-to-delete)
  ├── Shipping address entry (AddressEntryView sheet)
  ├── Price summary: subtotal + $9.99 shipping + 8% tax
  └── "Proceed to Payment"
        │
        ▼ CartViewModel.placeOrders()
          Creates one Firestore order per cart item
          Status: pending_payment
        │
        ▼
CheckoutView
  ├── Calls createPaymentIntent CF (server re-verifies price)
  ├── Shows Stripe PaymentSheet
  └── Payment result:
        ├── Success → navigates to OrderConfirmationView
        ├── Canceled → stays on CheckoutView
        └── Failed → reloads PaymentSheet for retry
              │
              (in parallel, Stripe fires webhook to handleStripeWebhook CF)
              (CF updates order: status = "paid", writes payment details)
        │
        ▼
OrderConfirmationView
  ├── Shows order ID, shipping address
  └── "Continue Shopping" → clears CartStore, dismisses sheet
```

### Analytics events tracked

Every event writes to the `userEvents` Firestore collection with `userId`, `sessionId` (UUID per app launch), `type`, `payload`, and `timestamp`.

| Event | Where fired | Payload |
|---|---|---|
| `catalog_viewed` | CatalogGridView appears | — |
| `product_viewed` | ProductDetailView appears | productId, productName |
| `eye_capture_started` | CameraView appears | — |
| `eye_capture_completed` | "Use Photo" tapped | — |
| `cart_viewed` | CartView appears | itemCount |
| `checkout_started` | placeOrders() called | orderCount |
| `payment_completed` | OrderConfirmationView appears | orderIds |
| `order_history_viewed` | OrderHistoryListView appears | — |

---

## 9. Admin Web Panel

Access at `http://localhost:5173` (dev) or your deployed URL.

Only users whose UID exists in the `admins` Firestore collection can log in. The app shows an "Access denied" screen for non-admin Firebase users.

### Adding an admin

**Emulator**: Open `localhost:4000` → Firestore → create `admins/{uid}` document (no fields required).

**Production**: Use the Firebase Console or Admin SDK. Never allow this through the client.

### Pages

#### Dashboard
- Revenue, pending fulfillment count, shipped count, delivered count
- 10 most recent orders table

#### Orders
- Filter by status tabs: All, Paid, In Production, Shipped, Delivered, Refunded
- Search by order ID, product name, or customer
- Click any row → OrderDetailPage

#### Order Detail
The primary order management interface. See [Order Lifecycle](#10-order-lifecycle) for the step-by-step workflow.

#### Products
- View all products (active and inactive)
- Edit: name, description, price, material, chain details, sort order, active/inactive toggle
- **Images**: upload files directly to Firebase Storage via the browser; set one image as "main" (shown in catalog); delete images
- Add new product: fill details, save, then upload images

#### Customers
- List of all registered users with order count and join date
- Click "View" → CustomerDetailPage

#### Customer Detail
- User profile (email, display name, join date, order count)
- Eye photo thumbnails (click to enlarge)
- Order history table (links to OrderDetailPage)
- Activity timeline: all `userEvents` grouped by session, with human-readable labels

---

## 10. Order Lifecycle

An order moves through these statuses. Only some transitions are valid.

```
pending_payment
      │
      │  Stripe webhook fires (payment_intent.succeeded)
      ▼
    paid
      │
      │  Admin clicks "Mark In Production"
      ▼
 in_production
      │
      │  Admin enters tracking number + carrier, clicks "Mark Shipped"
      ▼
   shipped
      │
      │  Admin clicks "Mark Delivered"
      ▼
  delivered          ← terminal state

  (from paid or in_production only)
      │  Admin clicks "Refund & Cancel"
      ▼
  refunded           ← terminal state
```

### What happens at each transition

| Transition | Who triggers | What happens |
|---|---|---|
| Created → `pending_payment` | iOS app | Order written to Firestore; order acknowledgement email sent (stub) |
| `pending_payment` → `paid` | Stripe webhook CF | Order updated with payment details; payment confirmation email sent (stub) |
| `paid` → `in_production` | Admin (web panel) | Admin writes status directly to Firestore; "in production" email + push sent |
| `in_production` → `shipped` | Admin (web panel) | Admin writes status + tracking details; shipping email + push sent |
| `shipped` → `delivered` | Admin (web panel) | Admin writes status; delivery push sent |
| `paid`/`in_production` → `refunded` | Admin (web panel) | `refundOrder` CF called; Stripe refund issued; order updated |

### Admin order processing steps

1. **New order arrives**: Status is `pending_payment`. Wait for Stripe to confirm payment (status changes to `paid` automatically via webhook).
2. **Order becomes `paid`**: Print the eye photo from the Customer Detail page (open eye photo → "Print"). Begin crafting the pendant.
3. **Pendant ready to ship**: Go to OrderDetailPage → "Mark In Production". Package the pendant.
4. **Shipped**: Enter tracking number and carrier → "Mark Shipped". Customer receives shipping notification.
5. **Confirmed delivered**: Click "Mark Delivered".
6. **Issue or refund request**: Click "Refund & Cancel" (only available on `paid` or `in_production` orders). This immediately issues a full Stripe refund.

### Accessing the eye photo for production

From **OrderDetailPage**: If the order has an eye photo, a "View Eye Photo" button appears. Click it to open the full-resolution image with print and download options.

From **CustomerDetailPage**: All of a customer's eye photos are shown as thumbnails. Click any to open the modal.

---

## 11. Data Models

### Product

```
products/{productId}
├── name: string
├── description: string
├── priceInCents: number
├── images: [
│     { storagePath: string, downloadURL: string, isMain: bool }
│   ]
├── pendantAnchorX: number        # normalized 0–1 X position for pendant on necklace photo
├── pendantAnchorY: number        # normalized 0–1 Y position
├── pendantDiameterFraction: number  # fraction of image width for pendant circle
├── material: string              # e.g. "Sterling Silver"
├── chain: { length: string, style: string }  # e.g. "18 inches", "Cable"
├── isActive: bool                # false = hidden from catalog
├── sortOrder: number             # ascending = first in grid
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

### Order

```
orders/{orderId}
├── userId: string                # Firebase Auth UID ("DELETED" if user was deleted)
├── status: string                # pending_payment | paid | in_production | shipped | delivered | refunded
├── productId: string
├── productSnapshot: {            # immutable copy of product at time of purchase
│     name, priceInCents, imageURL
│   }
├── eyePhotoId: string?          # null if no personalization
├── eyePhotoStoragePath: string? # Storage path to cropped eye (null if no personalization)
├── shipping: {
│     fullName, line1, line2?, city, state, postalCode, country
│   }
├── pricing: {
│     subtotalCents, shippingCents (999), taxCents, totalCents
│   }
├── payment: {                    # written by CF only
│     stripePaymentIntentId, stripeChargeId?, status, paidAt?,
│     refundId?, refundedAt?
│   }
├── fulfillment: {                # written by admin only
│     trackingNumber?, carrier?, shippedAt?
│   }
├── previewCompositeStoragePath: string?  # pendant preview composite image
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

### User

```
users/{uid}
├── email: string
├── displayName: string?
├── stripeCustomerId: string?     # set by createUserRecord CF
├── defaultShipping: Address?     # saved shipping address
├── createdAt: Timestamp
└── lastSignInAt: Timestamp
```

### EyePhoto

```
users/{uid}/eyePhotos/{photoId}
├── originalStoragePath: string   # full-resolution eye photo
├── croppedStoragePath: string    # circular cropped eye
├── capturedAt: Timestamp
├── isActive: bool
└── metadata: {
      detectionConfidence: number  # Vision framework confidence 0–1
    }
```

### UserEvent (analytics)

```
userEvents/{eventId}
├── userId: string
├── type: string                  # e.g. "product_viewed"
├── payload: object               # type-specific data
├── sessionId: string             # UUID, fresh each app launch
└── timestamp: Timestamp
```

---

## 12. Known Gaps & Pre-Production Checklist

These items must be resolved before the app is ready for real customers.

### Must-fix before launch

| Item | Location | What's needed |
|---|---|---|
| **Email service** | `functions/src/services/emailService.ts` | Integrate SendGrid or Resend; currently all methods are stubs that only log |
| **Stripe keys** | Firebase Secret Manager | Set `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PUBLISHABLE_KEY` in production Secret Manager |
| **Stripe webhook** | Stripe Dashboard | Point webhook to `handleStripeWebhook` CF URL; enable `payment_intent.succeeded` and `payment_intent.payment_failed` events |
| **Apple Developer Program** | Apple | Upgrade to paid account ($99/year) to enable App Store submission |
| **`DEVELOPMENT_TEAM`** | `project.yml` | Set your 10-character Team ID, re-run `xcodegen generate` |
| **Apple Pay merchant ID** | `IkeepAnEye/Features/Order/Services/StripeService.swift` | Replace `merchant.com.ikeepaneye` with your registered merchant ID |
| **`GoogleService-Info.plist`** | `IkeepAnEye/Resources/` | Download from Firebase Console and add to repo (gitignored — never commit) |

### Should configure before scale

| Item | Location | Note |
|---|---|---|
| **Shipping cost** | `CartViewModel.swift`, `OrderService.swift`, `createPaymentIntent.ts` | Hardcoded at $9.99; make configurable (Firestore config doc or CF env var) |
| **Tax rate** | Same three files | Hardcoded at 8%; varies by region |
| **Admin bootstrap script** | `functions/src/scripts/createAdmin.ts` | Use to create first admin in production (not via Console) |
| **Firestore indexes** | `firestore.indexes.json` | Deploy with `firebase deploy --only firestore:indexes` before going live |
| **Order fulfillment automation** | — | Currently manual; consider Printful/ShipStation integration |

### Development setup summary

```bash
# 1. Clone and install dependencies
git clone https://github.com/EricSeldonia/IkeepAnEye
cd IkeepAnEye/functions && npm install
cd ../web-admin && npm install

# 2. Generate Xcode project
cd .. && xcodegen generate

# 3. Add GoogleService-Info.plist to IkeepAnEye/Resources/ (get from Firebase Console)

# 4. Create functions/.secret.local with Stripe test keys

# 5. Create web-admin/.env.local with Firebase config + VITE_USE_EMULATOR=1

# 6. Start emulators
firebase emulators:start

# 7. Seed products
USE_EMULATOR=1 npx ts-node functions/src/scripts/seedProducts.ts

# 8. Create admin user
# - Open localhost:4000 → Auth → Add user
# - Copy the UID
# - Firestore → admins collection → New document with that UID

# 9. Run web admin
cd web-admin && npm run dev

# 10. Run iOS app in Xcode with USE_EMULATOR=1 environment variable set
```
