import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';

class ServicesPopupSheet extends StatelessWidget {
  const ServicesPopupSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ServicesPopupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    final services = [
      {
        'icon': Icons.local_parking_rounded,
        'title': 'Đặt chỗ trước',
        'subtitle': 'Giữ chỗ đỗ VIP nhanh chóng',
        'color': const Color(0xFF2563EB),
        'tag': 'Hot',
        'route': '/api/reservations',
      },
      {
        'icon': Icons.card_membership_rounded,
        'title': 'Gia hạn vé tháng',
        'subtitle': 'Tiết kiệm 15% khi gia hạn sớm',
        'color': const Color(0xFF059669),
        'tag': 'Ưu đãi',
        'route': '/api/MonthlySubscription/my',
      },
      {
        'icon': Icons.history_rounded,
        'title': 'Lịch sử vào / ra',
        'subtitle': 'Tra cứu phiên đỗ & hoá đơn VAT',
        'color': const Color(0xFF7C3AED),
        'tag': null,
        'route': '/api/ParkingSession/my',
      },
      {
        'icon': Icons.near_me_rounded,
        'title': 'Tìm vị trí xe',
        'subtitle': 'Định vị khu vực & chỉ đường',
        'color': const Color(0xFF0284C7),
        'tag': null,
        'route': 'find_car',
      },
      {
        'icon': Icons.contactless_rounded,
        'title': 'Cài đặt thẻ NFC',
        'subtitle': 'Chạm mở barrier không cần mở khoá',
        'color': const Color(0xFF0D9488),
        'tag': 'NFC',
        'route': 'nfc_setup',
      },
      {
        'icon': Icons.report_problem_outlined,
        'title': 'Báo cáo sự cố',
        'subtitle': 'Hỗ trợ kỹ thuật bãi đỗ 24/7',
        'color': const Color(0xFFDC2626),
        'tag': '24/7',
        'route': '/api/IncidentReport',
      },
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.space(20),
        context.space(12),
        context.space(20),
        context.space(24) + bottomPad,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.space(28)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle bar
          Center(
            child: Container(
              width: context.space(42),
              height: context.space(4.5),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(context.space(3)),
              ),
            ),
          ),
          SizedBox(height: context.space(16)),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.space(8)),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(context.space(12)),
                    ),
                    child: Icon(
                      Icons.widgets_rounded,
                      color: AppColors.primary,
                      size: context.iconSize(22),
                    ),
                  ),
                  SizedBox(width: context.space(12)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dịch vụ bãi xe',
                        style: TextStyle(
                          fontSize: context.sp(18),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Hệ thống quản lý đỗ xe thông minh PBMS',
                        style: TextStyle(
                          fontSize: context.sp(11),
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: const Color(0xFF64748B),
                  size: context.iconSize(20),
                ),
              ),
            ],
          ),

          SizedBox(height: context.space(18)),

          // Services Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: context.space(10),
              mainAxisSpacing: context.space(10),
              childAspectRatio: 1.85,
            ),
            itemBuilder: (context, index) {
              final s = services[index];
              final color = s['color'] as Color;
              final tag = s['tag'] as String?;

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đang mở: ${s['title']}'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(context.space(16)),
                child: Container(
                  padding: EdgeInsets.all(context.space(10)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(context.space(16)),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(context.space(7)),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(context.space(10)),
                                ),
                                child: Icon(
                                  s['icon'] as IconData,
                                  color: color,
                                  size: context.iconSize(19),
                                ),
                              ),
                              const Spacer(),
                              if (tag != null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.space(6),
                                    vertical: context.space(2),
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(context.space(6)),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: context.sp(9),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: context.space(6)),
                          Text(
                            s['title'] as String,
                            style: TextStyle(
                              fontSize: context.sp(12),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: context.space(1)),
                          Text(
                            s['subtitle'] as String,
                            style: TextStyle(
                              fontSize: context.sp(9.5),
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
