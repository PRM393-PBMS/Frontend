import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/subscriptions/presentation/screens/contract_screen.dart';

/// Danh sách hợp đồng vé tháng dài hạn của tôi (`GET /api/contracts/my`).
class MyContractsScreen extends StatefulWidget {
  const MyContractsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const MyContractsScreen()));

  @override
  State<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends State<MyContractsScreen> {
  late final _contracts = AsyncCubit(context.read<PbmsRepository>().getMyContracts);

  @override
  void dispose() {
    _contracts.close();
    super.dispose();
  }

  Future<void> _open(ContractModel c) async {
    await ContractScreen.open(context, c.subscriptionId);
    _contracts.load();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Hợp đồng của tôi',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: PbmsTokens.teal,
        onRefresh: () async => _contracts.load(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 14, 16, 32 + bottomInset),
              children: [
                const Text(
                  'Vé tháng từ 3 tháng trở lên cần ký hợp đồng điện tử. Hợp đồng đã ký được bãi niêm phong, có thể kiểm tra tính toàn vẹn bất cứ lúc nào.',
                  style: PbmsText.caption,
                ),
                const SizedBox(height: 14),
                PbmsAsync<List<ContractModel>>(
                  cubit: _contracts,
                  loadingHeight: 160,
                  errorTitle: 'Không tải được hợp đồng',
                  isEmpty: (d) => d.isEmpty,
                  empty: const PbmsEmptyView(
                    icon: Icons.description_outlined,
                    title: 'Chưa có hợp đồng nào',
                    message: 'Hợp đồng được tạo khi bạn đăng ký vé tháng từ 3 tháng trở lên.',
                  ),
                  builder: (items) => Column(
                    children: [
                      for (final c in items) ...[
                        _ContractTile(contract: c, onTap: () => _open(c)),
                        const SizedBox(height: 11),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContractTile extends StatelessWidget {
  final ContractModel contract;
  final VoidCallback onTap;

  const _ContractTile({required this.contract, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = contract;
    final when = c.isSigned ? c.signedAt : c.createdAt;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: PbmsCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: PbmsTokens.tealTint, shape: BoxShape.circle),
              child: const Icon(Icons.description_outlined, size: 20, color: PbmsTokens.teal),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hợp đồng ${c.contractNumber}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: PbmsText.bodyStrong),
                  if (when != null)
                    Text(
                      '${c.isSigned ? 'Ký lúc' : 'Tạo lúc'} ${DateFormatter.formatDateTime(when)}',
                      style: PbmsText.caption,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PbmsStatusPill(StatusInfo.contract(c.status)),
          ],
        ),
      ),
    );
  }
}
