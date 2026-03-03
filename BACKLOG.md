# IkeepAnEye — Backlog

Feature requests and planned improvements. Add new rows to the table; assign priority (High / Normal / Low).

---

| Priority | Area | Feature | Notes |
|---|---|---|---|
| Normal | iOS · Catalog | Product image thumbnail strip | In `ProductDetailView`, show all product images as small tappable thumbnails below the main large image. Tapping a thumbnail scrolls/jumps the main `TabView` to that image. Selected thumbnail highlighted with a rose border. |
| Normal | iOS · Cart & Orders | Display user's selected eye photo per product | In `CartView` and `OrderHistoryListView`/`OrderDetailView`, show the eye photo the user associated with each product (small oval thumbnail alongside the product row). Makes it clear which eye image is tied to which item. |
| Normal | Admin | Display Eye Photo in Order Detail | In the admin order detail view, show the eye photo the user selected for each order item alongside the product thumbnail. Fetch from Storage using `eyePhotoStoragePath` and render as a small oval image. |
