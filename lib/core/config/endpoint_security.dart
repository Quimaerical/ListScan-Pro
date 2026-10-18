/// Security helper that provides runtime endpoint resolution and XOR-based
/// obfuscation to prevent plain-text URL leaks in compiled binaries,
/// complying with security directives.
class EndpointSecurity {
  const EndpointSecurity._();

  static const int _xorKey = 0x5A;

  /// XOR-obfuscated char codes for: 'https://www.themealdb.com/api/json/v1/1/'
  static const List<int> _obfuscatedMealDbUrl = <int>[
    50,
    46,
    46,
    42,
    41,
    96,
    117,
    117,
    45,
    45,
    45,
    116,
    46,
    50,
    63,
    55,
    63,
    59,
    54,
    62,
    56,
    116,
    57,
    53,
    55,
    117,
    59,
    42,
    51,
    117,
    48,
    41,
    53,
    52,
    117,
    44,
    107,
    117,
    107,
    117,
  ];

  /// Resolves the TheMealDB base API URL.
  /// Prioritizes runtime overrides (--dart-define=MEALDB_API_URL=...)
  /// and falls back to de-obfuscating the embedded encrypted codes.
  static String getMealDbBaseUrl() {
    const String envUrl = String.fromEnvironment('MEALDB_API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    return decodeXor(_obfuscatedMealDbUrl, _xorKey);
  }

  /// XOR-obfuscated char codes for: 'https://forkify-api.herokuapp.com/api/v2/recipes/'
  static const List<int> _obfuscatedForkifyUrl = <int>[
    50,
    46,
    46,
    42,
    41,
    96,
    117,
    117,
    60,
    53,
    40,
    49,
    51,
    60,
    35,
    119,
    59,
    42,
    51,
    116,
    50,
    63,
    40,
    53,
    49,
    47,
    59,
    42,
    42,
    116,
    57,
    53,
    55,
    117,
    59,
    42,
    51,
    117,
    44,
    104,
    117,
    40,
    63,
    57,
    51,
    42,
    63,
    41,
    117,
  ];

  /// Resolves the Forkify Open API base URL.
  /// Prioritizes runtime overrides (--dart-define=FORKIFY_API_URL=...)
  /// and falls back to de-obfuscating the embedded encrypted codes.
  static String getForkifyBaseUrl() {
    const String envUrl = String.fromEnvironment('FORKIFY_API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    return decodeXor(_obfuscatedForkifyUrl, _xorKey);
  }

  /// Decodes a list of XOR-masked character codes using the provided [key].
  static String decodeXor(List<int> codes, int key) {
    return String.fromCharCodes(codes.map((int c) => c ^ key));
  }
}
