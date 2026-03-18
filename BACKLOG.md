# IkeepAnEye — Backlog

Feature requests and planned improvements. Add new rows to the table; assign priority (High / Normal / Low).

---

| ID | Priority | Status | Area | Feature | Notes |
|---|---|---|---|---|---|
| FR-001 | Normal | Closed | iOS · Catalog | Product image thumbnail strip | In `ProductDetailView`, show all product images as small tappable thumbnails below the main large image. Tapping a thumbnail scrolls/jumps the main `TabView` to that image. Selected thumbnail highlighted with a rose border. |
| FR-002 | Normal | Closed | iOS · Cart & Orders | Display user's selected eye photo per product | In `CartView` and `OrderHistoryListView`/`OrderDetailView`, show the eye photo the user associated with each product (small oval thumbnail alongside the product row). Makes it clear which eye image is tied to which item. |
| FR-003 | Normal | Closed | Admin | Display Eye Photo in Order Detail | In the admin order detail view, show the eye photo the user selected for each order item alongside the product thumbnail. Fetch from Storage using `eyePhotoStoragePath` and render as a small oval image. |
| FR-004 | Normal | Closed | Admin | Show User Addresses in Admin | In the admin customer detail page, display the user's `defaultShipping` address (read from `users/{uid}`) alongside their profile info. |
| FR-005 | Normal | Closed | Admin | Sortable Columns in Orders Table | In `OrdersPage`, clicking a column header sorts rows by that field; clicking again reverses order. Track `sortKey` + `sortDir` in local state, sort the filtered array before rendering. |
| FR-006 | Normal | Implemented | iOS · Profile | Edit User Profile | Allow the signed-in user to edit their display name and other profile fields from a dedicated Edit Profile screen in the Profile tab. |
| FR-007 | Normal | Implemented | iOS · EyeCapture | Reuse Saved Eye Photos | Eye photos captured by the user are persisted in Firestore/Storage and shown as selectable thumbnails in `ProductDetailView`, so they can be reused across future orders without recapturing. |
