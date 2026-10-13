import 'package:flutter/material.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import '../../data/models/mock_parking_lot.dart';

class ParkingBottomSheet extends StatelessWidget {
  final MockParkingLot parkingLot;

  const ParkingBottomSheet({super.key, required this.parkingLot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle for bottom sheet
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24.0),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),

            Text(
              parkingLot.name,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${CurrencyFormatter.format(parkingLot.pricePerHour)} / giờ',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.local_parking_rounded,
                  size: 20,
                  color: parkingLot.availableSlots > 0
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  '${parkingLot.availableSlots} / ${parkingLot.totalSlots} chỗ còn trống',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: parkingLot.availableSlots > 0
                    ? () {
                        // TODO: Implement Booking Flow
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Tính năng đặt chỗ đang được hoàn thiện.')),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: Text(
                  parkingLot.availableSlots > 0
                      ? 'Đặt chỗ ngay'
                      : 'Bãi đã hết chỗ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
