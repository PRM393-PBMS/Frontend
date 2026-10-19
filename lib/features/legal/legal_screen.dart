import 'package:flutter/material.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/features/legal/legal_documents.dart';

/// Trang đọc Điều khoản sử dụng / Chính sách bảo mật.
class LegalScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalScreen({super.key, required this.document});

  static Future<void> open(BuildContext context, LegalDocument document) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => LegalScreen(document: document)));

  @override
  Widget build(BuildContext context) {
    final d = document;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 4,
        title: Text(d.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PbmsTokens.ink)),
      ),
      body: SelectionArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 28 + bottom),
              children: [
                Text('Phiên bản ${d.version}, hiệu lực từ ${d.effectiveDate}', style: PbmsText.caption),
                const SizedBox(height: 12),
                Text(d.intro, style: PbmsText.body),
                for (final s in d.sections) ...[
                  const SizedBox(height: 22),
                  Semantics(
                    header: true,
                    child: Text(s.heading, style: PbmsText.section),
                  ),
                  for (final p in s.paragraphs) ...[
                    const SizedBox(height: 8),
                    Text(p, style: PbmsText.body),
                  ],
                  if (s.bullets.isNotEmpty) const SizedBox(height: 4),
                  for (final b in s.bullets)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 8, right: 10),
                            child: SizedBox.square(
                              dimension: 5,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: PbmsTokens.teal, shape: BoxShape.circle),
                              ),
                            ),
                          ),
                          Expanded(child: Text(b, style: PbmsText.body)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Đoạn chữ có liên kết "Điều khoản dịch vụ" và "Chính sách bảo mật" chạm được.
class LegalLinks extends StatelessWidget {
  final String prefix;
  final TextStyle style;
  final TextAlign textAlign;
  final bool includePrivacy;

  const LegalLinks({
    super.key,
    this.prefix = 'Tiếp tục đồng nghĩa với việc bạn đồng ý với ',
    this.style = const TextStyle(fontSize: 12, color: PbmsTokens.muted),
    this.textAlign = TextAlign.center,
    this.includePrivacy = true,
  });

  @override
  Widget build(BuildContext context) {
    final link = style.copyWith(
      color: PbmsTokens.teal,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: PbmsTokens.teal,
    );
    // WidgetSpan + GestureDetector: tránh phải quản lý vòng đời TapGestureRecognizer.
    InlineSpan tap(String text, LegalDocument doc) => WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Semantics(
            link: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => LegalScreen.open(context, doc),
              child: Text(text, style: link),
            ),
          ),
        );
    return Text.rich(
      TextSpan(
        text: prefix,
        style: style,
        children: [
          tap('Điều khoản dịch vụ', termsOfService),
          if (includePrivacy) ...[
            const TextSpan(text: ' và '),
            tap('Chính sách bảo mật', privacyPolicy),
          ],
        ],
      ),
      textAlign: textAlign,
    );
  }
}
