# Ảnh chờ gửi của staff

Nhánh `fix/staff-scan-retry` bổ sung lưu ảnh chờ gửi và lý do gửi lỗi. Không thay đổi API backend.

- Lưu trước khi gửi, riêng theo ID tài khoản; giữ cổng và giờ chụp ban đầu.
- Khôi phục khi mở lại màn hình; nhân viên chủ động chạm để gửi lại.
- Gửi thành công mới xóa ảnh khỏi hàng đợi. Nhấn giữ một thẻ để xóa thủ công sau xác nhận.
- Tối đa 8 ảnh, tổng dữ liệu ảnh 8MB, dùng shared_preferences đã có trong dự án. Khi đầy, gửi hoặc xóa ảnh cũ trước khi chụp tiếp.
- Phân biệt lỗi kết nối, hết phiên đăng nhập, thiếu quyền, ảnh quá lớn và lỗi máy chủ. Không lưu được trên thiết bị thì báo riêng và không bắt đầu upload.

Nếu request đã tới máy chủ nhưng phản hồi bị mất, thử gửi lại có thể tạo thêm lượt quét vì backend chưa hỗ trợ khóa chống trùng cho thao tác này. App nhắc kiểm tra lượt quét gần đây trước khi thử lại. Xóa dữ liệu ứng dụng hoặc gỡ app cũng xóa ảnh cục bộ.

## Kiểm tra

```powershell
flutter test test/staff_scanner_test.dart
flutter analyze
```

Đã chạy thành công 13 test case cho lưu/khôi phục, tách tài khoản, ghi đồng thời, giới hạn ảnh/dung lượng, dữ liệu hỏng, phân loại lỗi, gửi lại đúng cổng và giờ, xóa sau thành công, xác nhận xóa và rời màn hình khi upload chưa xong. Hai file test mới đã được xóa theo yêu cầu sau khi chạy. Lệnh trên chỉ chạy bộ test staff có sẵn.

Trên điện thoại: đăng nhập staff, chọn cổng, tắt mạng rồi chụp; mở lại app bằng cùng tài khoản và xác nhận ảnh còn. Bật mạng, kiểm tra lịch sử rồi gửi lại. Xác nhận web nhận ảnh và hàng đợi được dọn. Thử chụp nhiều ảnh khi mất mạng để xác nhận ảnh cũ không bị bỏ; nhấn giữ một ảnh để thử giữ/xóa. Camera và lưu dữ liệu trên thiết bị thật cần được kiểm tra riêng.
