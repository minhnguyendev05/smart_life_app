import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_app/models/finance_transaction.dart';
import 'package:smart_life_app/screens/finance/finance_shared_widgets.dart';

void main() {
  test('Funding source catalog keeps expected default options', () {
    expect(FinanceFundingSourceCatalog.options, isNotEmpty);

    final smartLife = FinanceFundingSourceCatalog.findById(
      FinanceTransaction.smartLifeFundingSourceId,
    );
    final outside = FinanceFundingSourceCatalog.findById(
      FinanceTransaction.defaultFundingSourceId,
    );

    expect(smartLife, isNotNull);
    expect(smartLife!.label, 'Ví SmartLife');
    expect(outside, isNotNull);
    expect(outside!.label, FinanceTransaction.defaultFundingSourceLabel);
  });

  test('Funding source catalog resolves legacy momo alias', () {
    final option = FinanceFundingSourceCatalog.findById('momo');

    expect(option, isNotNull);
    expect(option!.id, FinanceTransaction.smartLifeFundingSourceId);
  });
}
