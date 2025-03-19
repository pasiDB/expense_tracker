// This file is a simple helper to remind which command to run
// to generate the Hive adapters for our models.
//
// Run: flutter pub run build_runner build --delete-conflicting-outputs
//
// The command will generate the following adapter files:
// - lib/models/expense.g.dart
// - lib/models/user_profile.g.dart

void main() {
  print('To generate Hive adapters, run this command:');
  print('flutter pub run build_runner build --delete-conflicting-outputs');
}
