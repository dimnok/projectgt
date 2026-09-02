import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/features/contractors/data/models/contractor_model.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';

void main() {
  test('fromJson treats null phone and email as empty strings', () {
    final model = ContractorModel.fromJson({
      'id': '21242b41-fd13-4c0d-ad18-853943fdd470',
      'company_id': '437f2894-cb50-4ec2-9632-4a41987b3bb9',
      'full_name': 'ООО "ГРУППА КОМПАНИЙ "АГПАЙП"',
      'short_name': 'ООО "ГРУППА КОМПАНИЙ "АГПАЙП"',
      'inn': '7724387563',
      'director': 'Одиноков Александр Александрович',
      'legal_address': 'г Москва',
      'actual_address': 'г Москва',
      'phone': null,
      'email': null,
      'type': 'supplier',
    });

    expect(model.phone, '');
    expect(model.email, '');
    expect(model.type, ContractorType.supplier);
  });
}
