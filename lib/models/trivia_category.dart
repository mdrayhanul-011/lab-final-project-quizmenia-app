/// Represents a trivia category from OpenTDB.
class TriviaCategory {
  final int id;
  final String name;

  const TriviaCategory({
    required this.id,
    required this.name,
  });

  /// Cleans up verbose category prefixes like "Entertainment: " or "Science: "
  /// while keeping the full name available.
  String get displayName {
    if (name.contains(': ')) {
      return name.split(': ').last.trim();
    }
    return name;
  }

  /// Returns category group (e.g. "Entertainment", "Science", "General")
  String get group {
    if (name.contains(': ')) {
      return name.split(': ').first.trim();
    }
    return 'General';
  }

  factory TriviaCategory.fromJson(Map<String, dynamic> json) {
    return TriviaCategory(
      id: json['id'] as int,
      name: (json['name'] as String).trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriviaCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TriviaCategory(id: $id, name: $name)';
}
