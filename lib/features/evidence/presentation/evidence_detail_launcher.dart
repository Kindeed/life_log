import 'package:flutter/material.dart';
import 'package:life_log/common/widgets/app_bottom_sheet.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/presentation/evidence_detail_sheet.dart';

Future<void> showEvidenceDetailSheet(
  BuildContext context,
  ExpenseEvidence item,
) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EvidenceDetailSheet(item: item),
  );
}
