import 'package:flutter_test/flutter_test.dart';
import 'package:ledgr/features/pipeline/data/expense_category.dart';
import 'package:ledgr/features/pipeline/domain/keyword_categorizer.dart';

void main() {
  const c = KeywordCategorizer();

  test('matches well-known brands', () {
    expect(c.categorize('Netflix'), ExpenseCategory.subscriptions);
    expect(c.categorize('Uber Pakistan'), ExpenseCategory.transport);
    expect(c.categorize('AWS billing'), ExpenseCategory.tech);
    expect(c.categorize('Spotify Family'), ExpenseCategory.subscriptions);
  });

  test('matches generic words', () {
    expect(c.categorize('Office rent'), ExpenseCategory.rent);
    expect(c.categorize('Team salaries'), ExpenseCategory.salaries);
    expect(c.categorize('K-Electric bill'), ExpenseCategory.utilities);
    expect(c.categorize('Hotel in Lahore'), ExpenseCategory.travel);
  });

  test('case-insensitive', () {
    expect(c.categorize('NETFLIX'), ExpenseCategory.subscriptions);
    expect(c.categorize('UbEr'), ExpenseCategory.transport);
  });

  test('falls back to other for unknown', () {
    expect(c.categorize('Misc adjustment'), ExpenseCategory.other);
    expect(c.categorize(''), ExpenseCategory.other);
    expect(c.categorize('   '), ExpenseCategory.other);
  });
}
