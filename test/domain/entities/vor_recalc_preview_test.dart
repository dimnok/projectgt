import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/domain/entities/vor_recalc_preview.dart';

void main() {
  group('VorRecalcPreview.buildDisplayEntries', () {
    test('сворачивает пару removed+added с тем же объёмом', () {
      const preview = VorRecalcPreview(
        changes: [
          VorRecalcChange(
            changeType: VorRecalcChangeType.removed,
            section: 'КМС-1.8',
            rowLabel: '6 — L-профиль',
            unit: 'м.',
            oldQuantity: 89,
          ),
          VorRecalcChange(
            changeType: VorRecalcChangeType.added,
            section: 'КМС-1.8',
            rowLabel: '6 — L-профиль',
            unit: 'м',
            newQuantity: 89,
          ),
        ],
      );

      final entries = preview.displayEntries;
      expect(entries, hasLength(1));
      expect(entries.single, isA<VorRecalcMetadataSyncEntry>());

      final sync = entries.single as VorRecalcMetadataSyncEntry;
      expect(sync.quantity, 89);
      expect(sync.vorUnit, 'м.');
      expect(sync.journalUnit, 'м');
      expect(
        sync.tooltipMessage,
        contains('В ведомости: «м.»'),
      );
    });

    test('не сворачивает, если объёмы различаются', () {
      const preview = VorRecalcPreview(
        changes: [
          VorRecalcChange(
            changeType: VorRecalcChangeType.removed,
            section: 'КМС-1.8',
            rowLabel: '6 — L-профиль',
            unit: 'м',
            oldQuantity: 89,
          ),
          VorRecalcChange(
            changeType: VorRecalcChangeType.added,
            section: 'КМС-1.8',
            rowLabel: '6 — L-профиль',
            unit: 'м',
            newQuantity: 95,
          ),
        ],
      );

      expect(preview.displayEntries, hasLength(2));
      expect(
        preview.displayEntries.every((e) => e is VorRecalcVolumeEntry),
        isTrue,
      );
    });
  });
}
