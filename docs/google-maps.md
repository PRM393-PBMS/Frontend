# Google Maps

Màn **Tìm bãi đỗ** dùng `google_maps_flutter`. Khoá API không nằm trong git; mỗi máy tự đặt.

## Lấy khoá

1. Vào [Google Cloud Console](https://console.cloud.google.com/), tạo hoặc chọn project, bật **Billing**
   (Maps SDK cho Android/iOS miễn phí lượt tải bản đồ, nhưng Google vẫn bắt có tài khoản thanh toán).
2. **APIs & Services → Library**, bật: *Maps SDK for Android*, *Maps SDK for iOS*, và *Maps JavaScript API* nếu chạy bản web.
3. **Credentials → Create credentials → API key**. Giới hạn khoá:
   - Android: package `com.prm393.parking.prm393_frontend` + SHA-1 của keystore
     (`cd android && ./gradlew signingReport`).
   - iOS: bundle id của app.
   - Web: HTTP referrer, ví dụ `http://localhost:5173/*` và tên miền thật.

## Đặt khoá

| Nền tảng | File (không commit) | Nội dung |
|---|---|---|
| Android | `android/local.properties` | `MAPS_API_KEY=AIza...` (hoặc biến môi trường `MAPS_API_KEY` khi build CI) |
| iOS | `ios/Flutter/MapsKey.xcconfig` | `MAPS_API_KEY=AIza...` (xem `MapsKey.example.xcconfig`) |
| Web | `web/maps_key.js` | `window.PBMS_MAPS_KEY = 'AIza...';` (xem `maps_key.example.js`) |

Đổi khoá xong thì build lại app (`flutter run`), hot reload không đủ.

Thiếu khoá: Android/iOS hiện bản đồ trống (chỉ logo Google), danh sách bãi vẫn dùng được; web báo lỗi tải bản đồ.
