import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_aliases.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/models/exercise.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/services/exercise_match.dart';

const _hevyNames = {
  'Bench Press (Barbell)': 'Barbell Bench Press',
  'Squat (Barbell)': 'Barbell Full Squat',
  'Deadlift (Barbell)': 'Barbell Deadlift',
  'Lat Pulldown (Cable)': 'Cable Pulldown',
  'Seated Row (Cable)': 'Cable Seated Row',
  'Overhead Press (Barbell)': 'Barbell Standing Wide Military Press',
  'Shoulder Press (Dumbbell)': 'Dumbbell Standing Overhead Press',
  'Lateral Raise (Dumbbell)': 'Dumbbell Lateral Raise',
  'Bicep Curl (Dumbbell)': 'Dumbbell Biceps Curl',
  'Hammer Curl (Dumbbell)': 'Dumbbell Hammer Curl',
  'Triceps Pushdown (Cable)': 'Cable Pushdown',
  'Skullcrusher (Barbell)': 'Barbell Lying Triceps Extension',
  'Romanian Deadlift (Barbell)': 'Barbell Romanian Deadlift',
  'Bulgarian Split Squat (Dumbbell)': 'Dumbbell Single Leg Split Squat',
  'Chest Fly (Machine)': 'Pec Deck',
  'Chest Press (Machine)': 'Machine Chest Press',
  'T Bar Row': 'T-Bar Row',
  'Hip Abduction (Machine)': 'Hip Abduction Machine',
  'Leg Curl (Machine)': 'Seated Leg Curl',
  'Farmers Walk': 'Kettlebell Farmer Carry',
};

List<Exercise> _search(String query) => kExercises.where(exerciseSearch(query)).toList();

void main() {
  final byName = {for (final e in kExercises) e.name: e};

  test('every alias belongs to an exercise in the catalog', () {
    final orphans = kExerciseAliases.keys.where((name) => !byName.containsKey(name));
    expect(orphans, isEmpty);
  });

  test('no two exercises claim the same alias', () {
    final owners = <String, String>{};
    final clashes = <String>[];
    for (final entry in kExerciseAliases.entries) {
      for (final alias in entry.value) {
        final owner = owners.putIfAbsent(searchKey(alias), () => entry.key);
        if (owner != entry.key) clashes.add('$alias: $owner / ${entry.key}');
      }
    }
    expect(clashes, isEmpty);
  });

  test('searching a name from another app finds the exercise', () {
    for (final entry in _hevyNames.entries) {
      expect(_search(entry.key).map((e) => e.name), contains(entry.value),
          reason: 'searching "${entry.key}" should find ${entry.value}');
    }
  });

  test('importing a name from another app maps to the same exercise', () {
    for (final entry in _hevyNames.entries) {
      expect(matchExercise(entry.key, kExercises)?.name, entry.value);
    }
  });

  test('a half-typed name still narrows down to the exercise', () {
    expect(_search('lat pulld').map((e) => e.name), contains('Cable Pulldown'));
    expect(_search('db bench').map((e) => e.name), contains('Dumbbell Bench Press'));
    expect(_search('bulgarian split').map((e) => e.name), contains('Dumbbell Single Leg Split Squat'));
  });

  test('the plain catalog name still wins on its own', () {
    expect(_search('Barbell Bench Press').map((e) => e.name), contains('Barbell Bench Press'));
    expect(_search('pec deck').single.name, 'Pec Deck');
  });

  test('the names an AI writes land on a real exercise', () {
    const written = [
      'Bench Press', 'Squat', 'Deadlift', 'Overhead Press', 'Barbell Row',
      'Lat Pulldown', 'Bicep Curl', 'Tricep Pushdown', 'Leg Press',
      'Romanian Deadlift', 'Plank', 'Face Pull', 'Pull-ups', 'Push-ups',
      'Dumbbell Shoulder Press', 'Incline Bench Press', 'Leg Curl',
      'Calf Raises', 'Lateral Raises', 'Hip Thrust', 'Cable Fly',
      'Seated Row', 'Hammer Curls', 'Skull Crushers', 'Bulgarian Split Squat',
      'Goblet Squat', 'Russian Twist', 'Mountain Climbers',
    ];
    final missed = [for (final n in written) if (matchExercise(n, kExercises) == null) n];
    expect(missed, isEmpty, reason: 'sin emparejar: ${missed.join(", ")}');
  });

  test('the order of the words does not matter for an alias', () {
    expect(matchExercise('Dumbbell Shoulder Press', kExercises)?.name,
        'Dumbbell Standing Overhead Press');
    expect(matchExercise('Shoulder Press (Dumbbell)', kExercises)?.name,
        'Dumbbell Standing Overhead Press');
  });

  test('Portuguese names and common aliases search and import independent of UI language', () {
    setAppLanguage('en');
    expect(searchKey('elevação'), searchKey('elevacao'));
    expect(_search('elevacao lateral').map((e) => e.id), contains('DsgkuIt'));
    expect(_search('ELEVAÇÃO LATERAL').map((e) => e.id), contains('DsgkuIt'));
    expect(_search('triceps corda').map((e) => e.id), contains('rope-tricep-pushdown'));
    expect(_search('cadeira extensora').map((e) => e.id), contains('leg-extension'));
    expect(_search('mesa flexora').map((e) => e.id), contains('C5jncD2'));
    expect(_search('voador').map((e) => e.id), contains('pec-deck'));
    expect(matchExercise('Supino reto com barra', kExercises)?.id, 'EIeI8Vf');
    expect(matchExercise('voador', kExercises)?.id, 'pec-deck');
    expect(matchExercise('mesa flexora', kExercises)?.id, 'C5jncD2');
    expect(matchExercise('voador', [kExercises.firstWhere((e) => e.id == 'EIeI8Vf')]), isNull);

    final custom = Exercise(
      id: 'custom-voador', name: 'voador', primary: 'chest', secondary: const [],
      equipment: 'Other', difficulty: 'Beginner', art: '', steps: const [],
    );
    expect(matchExercise('voador', [custom, kExercises.firstWhere((e) => e.id == 'pec-deck')]), custom);
  });

  test('an empty search keeps the whole catalog', () {
    expect(_search('   ').length, kExercises.length);
  });
}
