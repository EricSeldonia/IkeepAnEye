# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

IkeepAnEye — an iOS app that lets users photograph their iris and order a custom iris-engraved pendant.

Repository: https://github.com/EricSeldonia/IkeepAnEye

## Stack

- **iOS 16.0+** · SwiftUI · MVVM
- **Firebase**: Auth (email/password), Firestore, Storage, Cloud Functions
- **Stripe**: `StripePaymentSheet` for payment
- **SDWebImageSwiftUI**: cached catalog images
- **XcodeGen**: `project.yml` generates the Xcode project

## Key Architecture

- `IkeepAnEyeApp.swift` — @main; injects `CartStore` as `@StateObject` EnvironmentObject
- `RootCoordinator.swift` — auth state → LandingView or MainTabView
- `CartStore.swift` — @MainActor ObservableObject; source of truth for cart
- `ProductService.swift` — Firestore real-time listener on `products` collection
- `IrisDetectionService.swift` — on-device Vision pipeline, never uploads until user confirms
- `StripeService.swift` — calls `createPaymentIntent` Cloud Function
- Cloud Functions in `functions/src/` (TypeScript, Node 20, firebase-functions v5)

## Developer Account

User has a **free Personal Team** (not paid Apple Developer Program).
- Sign in with Apple has been **removed** (requires paid account)
- Auth is email/password only
- Can build and run on personal device; cannot submit to App Store without upgrading

## Critical Setup Steps (one-time, not in repo)

1. Add `GoogleService-Info.plist` to `IkeepAnEye/Resources/` (gitignored — never commit)
2. Set `DEVELOPMENT_TEAM` in `project.yml`, then run `xcodegen generate`
3. Set `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PUBLISHABLE_KEY` in Firebase Secret Manager
4. Update `merchantId` in `StripeService.swift` to your Apple Pay merchant ID
5. Run `npm install` in `functions/` before deploying
6. Configure Stripe webhook pointing to `handleStripeWebhook` Cloud Function
7. Seed `products` collection: `USE_EMULATOR=1 npx ts-node functions/src/scripts/seedProducts.ts`

## Local Dev

```bash
firebase emulators:start          # Auth :9099, Firestore :8080, Storage :9199, Functions :5001, UI :4000
USE_EMULATOR=1 npx ts-node functions/src/scripts/seedProducts.ts   # seed 3 sample products
```

In Xcode scheme → Run → Arguments → Environment Variables: `USE_EMULATOR = 1`
This routes Auth, Firestore, Storage, and Functions to the local emulators.

## Known Gaps (pre-production)

- **Email service** (`functions/src/services/emailService.ts`) is a stub — needs SendGrid/Resend integration
- **Shipping cost & tax** are hardcoded (999¢ + 8%) — make configurable before multi-region launch
- **Apple Pay merchant ID** hardcoded in `StripeService.swift` — update to match Stripe/Apple setup
- **No order fulfillment automation** — order status stays "paid" until manually updated in console
