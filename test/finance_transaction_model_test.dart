import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_app/models/finance_recurring_transaction.dart';
import 'package:smart_life_app/models/finance_transaction.dart';

void main() {
  test('normalizeFundingSourceId handles aliases and unknown values', () {
    expect(
      FinanceTransaction.normalizeFundingSourceId('momo'),
      FinanceTransaction.smartLifeFundingSourceId,
    );
    expect(
      FinanceTransaction.normalizeFundingSourceId('  other-wallet  '),
      FinanceTransaction.defaultFundingSourceId,
    );
    expect(
      FinanceTransaction.normalizeFundingSourceId(''),
      FinanceTransaction.defaultFundingSourceId,
    );
    expect(
      FinanceTransaction.normalizeFundingSourceId('new-bank'),
      FinanceTransaction.smartLifeFundingSourceId,
    );
  });

  test('FinanceTransaction.fromMap parses legacy dynamic fields safely', () {
    final transaction = FinanceTransaction.fromMap({
      'id': 'trx-1',
      'title': 'Legacy',
      'amount': 120000,
      'category': 'Ăn uống',
      'type': 'expense',
      'createdAt': '2026-04-09T08:30:00.000',
      'includedInReports': '0',
      'fundingSourceId': 'momo',
      'categoryIconCodePoint': '59000',
      'categoryIconMatchTextDirection': '1',
      'categoryIconColorValue': '4294198070',
    });

    expect(transaction.amount, 120000);
    expect(transaction.includedInReports, isFalse);
    expect(
      transaction.fundingSourceId,
      FinanceTransaction.smartLifeFundingSourceId,
    );
    expect(transaction.categoryIconCodePoint, 59000);
    expect(transaction.categoryIconMatchTextDirection, isTrue);
    expect(transaction.categoryIconColorValue, 4294198070);
  });

  test('FinanceTransaction.copyWith can clear icon snapshot', () {
    final base = FinanceTransaction(
      id: 'trx-2',
      title: 'Coffee',
      amount: 30000,
      category: 'Ăn uống',
      type: TransactionType.expense,
      createdAt: DateTime(2026, 4, 9, 9, 0),
      categoryIconCodePoint: 59001,
      categoryIconFontFamily: 'MaterialIcons',
      categoryIconMatchTextDirection: false,
      categoryIconColorValue: 0xFFF26AB8,
    );

    final updated = base.copyWith(
      category: 'Khác',
      clearCategoryIconSnapshot: true,
    );

    expect(updated.category, 'Khác');
    expect(updated.categoryIconCodePoint, isNull);
    expect(updated.categoryIconFontFamily, isNull);
    expect(updated.categoryIconMatchTextDirection, isNull);
    expect(updated.categoryIconColorValue, isNull);
  });

  test('FinanceRecurringTransaction.fromMap uses shared funding normalization', () {
    final recurring = FinanceRecurringTransaction.fromMap({
      'id': 'rec-1',
      'title': 'Rent',
      'amount': 5000000,
      'type': 'expense',
      'category': 'Nhà cửa',
      'fundingSourceId': 'momo',
      'frequency': 'monthly',
      'startDate': '2026-04-01T00:00:00.000',
      'nextDate': '2026-05-01T00:00:00.000',
      'createdAt': '2026-04-01T00:00:00.000',
      'categoryIconMatchTextDirection': 1,
    });

    expect(
      recurring.fundingSourceId,
      FinanceTransaction.smartLifeFundingSourceId,
    );
    expect(
      recurring.fundingSourceLabel,
      FinanceTransaction.defaultFundingSourceLabel,
    );
    expect(recurring.categoryIconMatchTextDirection, isTrue);
  });
}
