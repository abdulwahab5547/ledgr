import '../data/expense_category.dart';

/// Local, no-ML categorizer. Returns the first category whose keywords match
/// any token in [label] (case-insensitive substring). Order matters — more
/// specific keywords come first. Falls back to [ExpenseCategory.other].
///
/// Used by `RecurringFormSheet` to pre-fill the category when the user types
/// a label like "Netflix" → Subscriptions, "Uber" → Transport.
class KeywordCategorizer {
  const KeywordCategorizer();

  static const _rules = <(ExpenseCategory, List<String>)>[
    (
      ExpenseCategory.rent,
      ['rent', 'lease', 'mortgage', 'apartment', 'housing'],
    ),
    (
      ExpenseCategory.salaries,
      ['salary', 'salaries', 'payroll', 'wages'],
    ),
    (
      ExpenseCategory.subscriptions,
      [
        'netflix',
        'spotify',
        'hulu',
        'disney',
        'youtube',
        'apple tv',
        'icloud',
        'google one',
        'subscription',
        'membership',
        'patreon',
        'substack',
      ],
    ),
    (
      ExpenseCategory.utilities,
      [
        'electricity',
        'electric',
        'gas',
        'water',
        'internet',
        'wifi',
        'broadband',
        'mobile',
        'phone',
        'utilities',
        'utility',
        'kse',
        'wapda',
        'ssgc',
        'sui gas',
      ],
    ),
    (
      ExpenseCategory.transport,
      [
        'uber',
        'careem',
        'lyft',
        'taxi',
        'cab',
        'fuel',
        'petrol',
        'diesel',
        'metro',
        'bus',
        'train',
      ],
    ),
    (
      ExpenseCategory.travel,
      [
        'flight',
        'airline',
        'hotel',
        'airbnb',
        'booking',
        'travel',
        'trip',
        'vacation',
      ],
    ),
    (
      ExpenseCategory.tech,
      [
        'github',
        'aws',
        'gcp',
        'azure',
        'cursor',
        'vercel',
        'figma',
        'notion',
        'linear',
        'jetbrains',
        'openai',
        'anthropic',
      ],
    ),
    (
      ExpenseCategory.healthcare,
      [
        'doctor',
        'hospital',
        'pharmacy',
        'medicine',
        'health',
        'insurance',
        'gym',
      ],
    ),
    (
      ExpenseCategory.food,
      [
        'food',
        'grocer',
        'grocery',
        'restaurant',
        'foodpanda',
        'meal',
        'lunch',
        'dinner',
        'breakfast',
      ],
    ),
    (
      ExpenseCategory.entertainment,
      [
        'cinema',
        'movie',
        'concert',
        'event',
        'tickets',
        'steam',
        'playstation',
        'xbox',
      ],
    ),
  ];

  ExpenseCategory categorize(String label) {
    final lower = label.toLowerCase();
    if (lower.trim().isEmpty) return ExpenseCategory.other;
    for (final rule in _rules) {
      for (final keyword in rule.$2) {
        if (lower.contains(keyword)) return rule.$1;
      }
    }
    return ExpenseCategory.other;
  }
}
