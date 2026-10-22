import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';

/// Một băng quảng cáo trên trang chủ: ảnh nền, tiêu đề, mô tả và nút hành động.
class PromoItem {
  final String image;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  const PromoItem({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });
}

/// Băng quảng cáo trượt ngang. Mặc định chỉ đổi ảnh khi khách vuốt, để không trượt
/// dưới ngón cái lúc đang cuộn; truyền [interval] để tự chuyển ảnh.
/// Chế độ giảm chuyển động thì không bao giờ tự chuyển.
class PromoCarousel extends StatefulWidget {
  final List<PromoItem> items;
  final Duration? interval;

  const PromoCarousel({
    super.key,
    required this.items,
    this.interval,
  });

  static const double height = 164;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  // Bắt đầu ở giữa một dải rất dài để vuốt vòng tròn được cả hai phía.
  static const _loop = 10000;
  late final PageController _page =
      PageController(initialPage: _loop ~/ 2 * widget.items.length);
  Timer? _timer;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final item in widget.items) {
      precacheImage(AssetImage(item.image), context);
    }
    _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final interval = widget.interval;
    if (interval == null || reduceMotion || widget.items.length < 2) return;
    _timer = Timer.periodic(interval, (_) {
      if (!_page.hasClients) return;
      _page.nextPage(
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Column(
      children: [
        SizedBox(
          height: PromoCarousel.height,
          child: NotificationListener<ScrollStartNotification>(
            // Vuốt tay: đếm lại để ảnh không bị chuyển ngay sau khi thả.
            onNotification: (n) {
              if (n.dragDetails != null) _restart();
              return false;
            },
            child: PageView.builder(
              controller: _page,
              itemCount: _loop * items.length,
              onPageChanged: (i) => setState(() => _index = i % items.length),
              itemBuilder: (context, i) =>
                  _PromoCard(item: items[i % items.length]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < items.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index ? PbmsTokens.teal : PbmsTokens.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final PromoItem item;

  const _PromoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.title}. ${item.subtitle}. ${item.action}',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: PbmsTokens.ink,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(item.image, fit: BoxFit.cover),
              // Phủ tối phần dưới để chữ trắng đọc rõ trên mọi ảnh.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.1, 1],
                    colors: [Color(0x000F172A), Color(0xD90F172A)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5, color: Color(0xE6FFFFFF))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(item.action,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: PbmsTokens.teal)),
                    ),
                  ],
                ),
              ),
              // Hiệu ứng chạm vẽ trên ảnh.
              Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: item.onTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
