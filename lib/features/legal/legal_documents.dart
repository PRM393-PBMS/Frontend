/// Nội dung Điều khoản sử dụng và Chính sách bảo mật của PBMS.
///
/// Viết theo đúng cách app và máy chủ đang hoạt động. Khi đổi nội dung quan trọng,
/// tăng [LegalDocument.version] và cập nhật [LegalDocument.effectiveDate].
class LegalSection {
  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;

  const LegalSection(this.heading, {this.paragraphs = const [], this.bullets = const []});
}

class LegalDocument {
  final String title;
  final String version;
  final String effectiveDate;
  final String intro;
  final List<LegalSection> sections;

  const LegalDocument({
    required this.title,
    required this.version,
    required this.effectiveDate,
    required this.intro,
    required this.sections,
  });
}

const _operator = 'Ban quản lý Bãi đỗ xe PBMS';

const termsOfService = LegalDocument(
  title: 'Điều khoản sử dụng dịch vụ',
  version: '1.0',
  effectiveDate: '19/10/2026',
  intro: 'Điều khoản này áp dụng khi bạn dùng ứng dụng PBMS Smart Parking và các bãi đỗ do '
      '$_operator (sau đây gọi là "PBMS") vận hành. Bằng việc tạo tài khoản hoặc tiếp tục sử dụng, '
      'bạn xác nhận đã đọc và đồng ý với Điều khoản này và Chính sách bảo mật.',
  sections: [
    LegalSection('1. Tài khoản', bullets: [
      'Bạn đăng ký bằng email (xác thực qua mã OTP), đặt tên đăng nhập và mật khẩu. Thông tin khai báo phải đúng và là của chính bạn.',
      'Bạn tự bảo mật mật khẩu và thiết bị; mọi thao tác thực hiện từ tài khoản được coi là do bạn thực hiện. Có thể bật khoá bằng sinh trắc học để tăng bảo vệ.',
      'Khi nghi ngờ tài khoản bị lộ, hãy đổi mật khẩu ngay trong mục Cá nhân. Đổi mật khẩu sẽ đăng xuất các thiết bị khác.',
      'Người chưa thành niên sử dụng dịch vụ cần có sự đồng ý của cha mẹ hoặc người giám hộ.',
    ]),
    LegalSection('2. Phương tiện và biển số', bullets: [
      'Bạn chỉ khai báo xe mình sở hữu hoặc được phép sử dụng, đúng biển số và loại xe.',
      'Camera tại cổng đọc biển số để nhận diện xe. Biển số bị che, bẩn hoặc không khớp có thể khiến xe không được nhận diện tự động; khi đó nhân viên sẽ kiểm tra thủ công.',
      'Không thể xoá hoặc đổi loại xe đang gắn với vé tháng, đặt chỗ hay lượt gửi; đổi xe của vé tháng thực hiện qua yêu cầu đổi xe.',
    ]),
    LegalSection('3. Các hình thức gửi xe', bullets: [
      'Gửi lượt: vào bãi bình thường hoặc dùng mã QR vào bãi một lần tạo trên app. Mã QR gắn với một xe, hiệu lực 24 giờ, chỉ dùng được một lần và bị huỷ khi bạn tạo mã mới cho cùng xe. Không chia sẻ mã cho người khác.',
      'Đặt chỗ trước (chỉ ô tô): đặt trước tối đa 5 giờ, đặt cọc bằng giá giờ đầu; tiền cọc được trừ vào phí khi ra bãi. Không đổi giờ trong 15 phút trước giờ hẹn. Bãi nhận xe trong khoảng 30 phút trước đến 30 phút sau giờ hẹn.',
      'Vé tháng: các kỳ hạn 1, 3, 6, 9, 12 tháng; áp dụng tại bãi bạn chọn hoặc tại mọi bãi tuỳ gói. Gói từ 3 tháng trở lên phải ký hợp đồng điện tử trước khi thanh toán. Ô cố định (nếu có) được giữ riêng cho xe đã đăng ký trong suốt thời hạn vé.',
      'Vé chỉ có hiệu lực cho đúng xe và đúng bãi ghi trên vé.',
    ]),
    LegalSection('4. Giá và thanh toán', bullets: [
      'Bảng giá theo loại xe được công bố trong app tại thời điểm sử dụng (giá giờ đầu, giá các giờ sau, phụ thu nếu có). Phí tính theo giờ, phần lẻ tính tròn lên một giờ.',
      'Bạn có thể thanh toán qua cổng PayOS (chuyển khoản QR ngân hàng, thẻ), bằng ví PBMS, hoặc tiền mặt tại cổng.',
      'Ví PBMS được nạp qua PayOS, mỗi lần từ 2.000 đ đến 10.000.000 đ. Số dư ví chỉ dùng để trả phí dịch vụ PBMS.',
      'Thanh toán trước trên app khi xe còn trong bãi sẽ được cấp mã ra cổng; mã có hiệu lực tới khi xe rời bãi.',
      'Việc hoàn tiền (nếu có) thực hiện theo điều kiện hiển thị tại thời điểm giao dịch và quy định pháp luật.',
    ]),
    LegalSection('5. Hợp đồng điện tử', paragraphs: [
      'Với vé từ 3 tháng, bạn đọc hợp đồng, xác nhận đồng ý, nhập họ tên và ký tay trên màn hình. '
          'Hệ thống ghi nhận thời điểm ký và niêm phong số nội dung hợp đồng để phát hiện mọi chỉnh sửa về sau. '
          'Hợp đồng đã ký có giá trị như văn bản giao kết giữa bạn và PBMS; bạn có thể xem lại trong app.',
    ]),
    LegalSection('6. Trách nhiệm của bạn', bullets: [
      'Tuân thủ nội quy bãi, hướng dẫn của nhân viên, biển báo và sơ đồ ô đỗ; đỗ đúng ô được chỉ định.',
      'Khoá xe, không để trẻ em, vật nuôi hoặc chất dễ cháy nổ trong xe; tự quản lý tài sản cá nhân để trong xe.',
      'Không dùng app hoặc mã QR để gian lận, giả mạo biển số hoặc can thiệp vào hệ thống.',
    ]),
    LegalSection('7. Trách nhiệm của PBMS', bullets: [
      'Bố trí chỗ đỗ theo vé và đặt chỗ hợp lệ, vận hành camera và nhân viên tại bãi, giữ dữ liệu của bạn theo Chính sách bảo mật.',
      'Bồi thường thiệt hại phát sinh do lỗi của PBMS theo quy định của pháp luật. PBMS không chịu trách nhiệm với thiệt hại do bạn vi phạm Điều khoản, do lỗi của bên thứ ba hoặc do sự kiện bất khả kháng.',
      'Dịch vụ trên app có thể tạm gián đoạn để bảo trì hoặc do sự cố kỹ thuật; khi đó bạn vẫn có thể gửi xe và thanh toán trực tiếp tại cổng.',
    ]),
    LegalSection('8. Sự cố và khiếu nại', paragraphs: [
      'Báo sự cố (va chạm, mất mát, sai phí...) qua mục Báo cáo sự cố trong app, kèm ảnh nếu có, hoặc trực tiếp với nhân viên tại bãi. '
          'PBMS tiếp nhận, phản hồi trong app và giải quyết theo quy định của pháp luật về bảo vệ quyền lợi người tiêu dùng.',
    ]),
    LegalSection('9. Tạm khoá tài khoản', paragraphs: [
      'PBMS có thể tạm khoá hoặc khoá tài khoản khi phát hiện gian lận, khai báo sai, nợ phí kéo dài hoặc vi phạm nghiêm trọng Điều khoản, '
          'và sẽ thông báo lý do. Bạn có thể liên hệ để được xem xét lại.',
    ]),
    LegalSection('10. Thay đổi điều khoản', paragraphs: [
      'Khi thay đổi Điều khoản, PBMS thông báo trong app trước khi áp dụng. Thay đổi không ảnh hưởng tới vé tháng và hợp đồng đã ký trước đó cho tới khi hết hạn.',
    ]),
    LegalSection('11. Luật áp dụng', paragraphs: [
      'Điều khoản này được điều chỉnh bởi pháp luật Việt Nam. Tranh chấp được ưu tiên giải quyết bằng thương lượng; '
          'nếu không thành, một trong các bên có thể đưa ra cơ quan có thẩm quyền theo quy định.',
    ]),
    LegalSection('12. Liên hệ', paragraphs: [
      '$_operator: qua mục Báo cáo sự cố trong app hoặc quầy quản lý tại bãi.',
    ]),
  ],
);

const privacyPolicy = LegalDocument(
  title: 'Chính sách bảo mật thông tin',
  version: '1.0',
  effectiveDate: '19/10/2026',
  intro: 'Chính sách này cho biết PBMS thu thập dữ liệu cá nhân nào, dùng vào việc gì, chia sẻ với ai và '
      'bạn có những quyền gì. $_operator là bên kiểm soát và xử lý dữ liệu cá nhân của bạn, thực hiện theo '
      'quy định của pháp luật Việt Nam về bảo vệ dữ liệu cá nhân.',
  sections: [
    LegalSection('1. Dữ liệu chúng tôi thu thập', bullets: [
      'Tài khoản: tên đăng nhập, họ tên, email, số điện thoại, ảnh đại diện (nếu bạn tải lên). Mật khẩu chỉ được lưu dưới dạng mã băm, không ai đọc được.',
      'Phương tiện: biển số, loại xe, tên và mẫu xe bạn tự đặt.',
      'Gửi xe: giờ vào / ra, cổng, ô đỗ, ảnh chụp xe và người lái tại cổng, mã QR vào bãi, mã ra cổng.',
      'Giao dịch: số tiền, phương thức, mã đơn hàng, trạng thái thanh toán, lịch sử ví. PBMS không nhận và không lưu số thẻ hay thông tin tài khoản ngân hàng của bạn; các thông tin này do PayOS và ngân hàng xử lý.',
      'Vé tháng và hợp đồng: gói, thời hạn, ô cố định, họ tên người ký, ảnh chữ ký, địa chỉ IP và thời điểm ký.',
      'Báo cáo sự cố: nội dung và ảnh bạn gửi.',
      'Dữ liệu kỹ thuật: nhật ký truy cập máy chủ phục vụ vận hành và bảo mật.',
    ]),
    LegalSection('2. Dữ liệu chỉ nằm trên điện thoại của bạn', bullets: [
      'Vị trí: chỉ dùng trên máy để gợi ý bãi gần bạn và hiển thị trên bản đồ, không gửi lên máy chủ PBMS.',
      'Sinh trắc học (vân tay, khuôn mặt): do hệ điều hành xác thực; app chỉ nhận kết quả đúng / sai, không đọc hay lưu dữ liệu sinh trắc học.',
      'Ảnh từ máy ảnh / thư viện: chỉ những ảnh bạn chọn để làm ảnh đại diện hoặc gửi kèm báo cáo sự cố mới được tải lên.',
    ]),
    LegalSection('3. Mục đích sử dụng', bullets: [
      'Tạo và bảo vệ tài khoản, xác thực đăng nhập, gửi mã OTP.',
      'Nhận diện xe tại cổng, ghi nhận lượt gửi, giữ chỗ, quản lý vé tháng và ô cố định.',
      'Tính phí, xử lý thanh toán, nạp và trừ ví, cấp mã ra cổng.',
      'Ký, lưu và kiểm tra tính toàn vẹn của hợp đồng vé tháng.',
      'Gửi thông báo về đặt chỗ, thanh toán, vé tháng và lượt gửi xe.',
      'Giải quyết sự cố, khiếu nại; bảo đảm an ninh bãi và phòng chống gian lận.',
      'Thực hiện nghĩa vụ theo yêu cầu của pháp luật (kế toán, thuế, cơ quan nhà nước có thẩm quyền).',
    ]),
    LegalSection('4. Chia sẻ dữ liệu', paragraphs: [
      'PBMS không bán dữ liệu cá nhân của bạn. Dữ liệu chỉ được chia sẻ ở mức cần thiết với:',
    ], bullets: [
      'PayOS: thông tin đơn hàng (số tiền, nội dung) để tạo link và mã QR thanh toán.',
      'Plate Recognizer: ảnh chụp tại cổng để đọc biển số tự động.',
      'Nhà cung cấp hạ tầng: máy chủ ứng dụng (Render), cơ sở dữ liệu, dịch vụ gửi email (Resend) để gửi mã OTP.',
      'Máy chủ bản đồ OpenStreetMap France: nhận địa chỉ IP và vùng bản đồ bạn đang xem để trả ảnh bản đồ (không kèm vị trí GPS hay thông tin tài khoản).',
      'Cơ quan nhà nước có thẩm quyền khi có yêu cầu hợp pháp.',
    ]),
    LegalSection('5. Lưu trữ ngoài Việt Nam', paragraphs: [
      'Một số nhà cung cấp nêu trên đặt máy chủ ngoài Việt Nam, vì vậy dữ liệu của bạn có thể được lưu trữ hoặc xử lý ở nước ngoài. '
          'PBMS chỉ chuyển dữ liệu cần thiết cho từng dịch vụ và thực hiện các thủ tục theo quy định của pháp luật.',
    ]),
    LegalSection('6. Thời gian lưu trữ', bullets: [
      'Dữ liệu tài khoản và phương tiện: trong thời gian tài khoản còn hoạt động.',
      'Lịch sử gửi xe, giao dịch, hợp đồng: trong thời hạn pháp luật yêu cầu lưu chứng từ, kể cả sau khi tài khoản bị xoá.',
      'Mã QR vào bãi và mã ra cổng: hết hiệu lực sau khi sử dụng hoặc hết hạn.',
    ]),
    LegalSection('7. Bảo mật', bullets: [
      'Mọi kết nối giữa app và máy chủ được mã hoá (HTTPS).',
      'Mật khẩu được băm; phiên đăng nhập dùng mã thông báo có thời hạn, lưu trong vùng bảo mật của thiết bị.',
      'Hợp đồng được niêm phong số để phát hiện chỉnh sửa trái phép.',
      'Nhật ký hệ thống che mật khẩu, mã OTP, mã thông báo và ảnh chữ ký.',
      'Chỉ nhân viên có nhiệm vụ mới được truy cập dữ liệu, trong phạm vi công việc.',
    ]),
    LegalSection('8. Quyền của bạn', paragraphs: [
      'Theo quy định của pháp luật về bảo vệ dữ liệu cá nhân, bạn có quyền:',
    ], bullets: [
      'Được biết về việc xử lý dữ liệu và đồng ý hoặc rút lại sự đồng ý.',
      'Truy cập và chỉnh sửa dữ liệu: tự sửa hồ sơ, ảnh đại diện, xe trong mục Cá nhân.',
      'Yêu cầu xoá, hạn chế xử lý, phản đối xử lý hoặc nhận bản sao dữ liệu của mình.',
      'Khiếu nại, tố cáo và yêu cầu bồi thường khi quyền bị vi phạm.',
      'Gửi yêu cầu qua mục Báo cáo sự cố hoặc tại quầy quản lý; PBMS phản hồi trong thời hạn pháp luật quy định. '
          'Việc rút lại đồng ý hoặc xoá dữ liệu có thể khiến một số dịch vụ (vé tháng, đặt chỗ) không tiếp tục được.',
    ]),
    LegalSection('9. Quyền truy cập trên thiết bị', paragraphs: [
      'App chỉ xin quyền khi bạn dùng tính năng tương ứng và bạn có thể tắt bất cứ lúc nào trong Cài đặt của điện thoại: '
          'vị trí (gợi ý bãi gần), máy ảnh và thư viện ảnh (ảnh đại diện, báo sự cố), thông báo (thông báo đẩy), '
          'sinh trắc học (khoá app). Từ chối quyền không ảnh hưởng tới các chức năng khác.',
    ]),
    LegalSection('10. Thay đổi chính sách', paragraphs: [
      'Khi thay đổi Chính sách, PBMS thông báo trong app và cập nhật ngày hiệu lực ở đầu trang này.',
    ]),
    LegalSection('11. Liên hệ', paragraphs: [
      '$_operator: qua mục Báo cáo sự cố trong app hoặc quầy quản lý tại bãi.',
    ]),
  ],
);
