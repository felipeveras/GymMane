import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/l10n/catalog_it.dart';
import 'package:gymmane/l10n/catalog_zh.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/l10n/catalog_pt.dart';
import 'package:gymmane/models/exercise.dart';
import 'package:gymmane/services/exercise_match.dart' show sortedKey;

void main() {
  tearDown(() => setAppLanguage('en'));

  test('Portuguese locale displays a Brazilian built-in name and preserves fallback', () {
    final bench = kExercises.firstWhere((e) => e.id == 'EIeI8Vf');
    final custom = Exercise(
      id: 'custom-pt-test',
      name: 'Supino da minha academia',
      primary: 'chest',
      secondary: const [],
      equipment: 'Other',
      difficulty: 'Beginner',
      art: '',
      steps: const [],
    );

    for (final language in ['en', 'pt-BR', 'pt_BR', 'es', 'it', 'zh']) {
      setAppLanguage(language);
      if (language.startsWith('pt')) expect(appLanguage, 'pt');
      expect(exerciseName(custom), custom.name, reason: 'custom name under $language');
      expect(exerciseSteps(custom), custom.steps, reason: 'custom steps under $language');
    }
    setAppLanguage('pt-BR');
    expect(exerciseName(bench), 'Supino reto com barra');
    setAppLanguage('pt_BR');
    expect(exerciseName(bench), 'Supino reto com barra');
  });

  test('Portuguese names cover exactly the built-in IDs and keep variants distinct', () {
    final ids = kExercises.map((e) => e.id).toSet();
    expect(kExerciseNamePt.keys.toSet(), ids);
    expect(kExerciseNamePt.values.every((name) => name.trim().isNotEmpty), isTrue);
    expect(
      kExerciseNamePt.values.map((name) => name.toLowerCase()).toSet().length,
      kExerciseNamePt.length,
      reason: 'each built-in must have a distinguishable Portuguese name',
    );
    expect(kExerciseNamePt['leg-extension'], 'Cadeira extensora');
    expect(kExerciseNamePt['C5jncD2'], 'Mesa flexora');
    expect(kExerciseNamePt['seated-leg-curl'], 'Cadeira flexora');
    expect(kExerciseNamePt['hip-abduction-machine'], 'Cadeira abdutora');
    expect(kExerciseNamePt['hip-adduction-machine'], 'Cadeira adutora');
    expect(kExerciseNamePt['qOgPVf6'], 'Rosca Scott com barra');
    expect(kExerciseNamePt['DsgkuIt'], 'Elevação lateral com halteres');
    expect(kExerciseNamePt['wQ2c4XD'], 'Levantamento terra romeno com barra');
  });

  test('reviewed Portuguese labels preserve the exercise movement and details', () {
    expect(kExerciseNamePt['BbfB8Gb'], 'Toque nas pontas dos pés');
    expect(kExerciseNamePt['FkBIE6a'], 'Mesa flexora com halter');
    expect(kExerciseNamePt['Zwiw7XR'], 'Rosca alternada em pé com halteres e um pé na bola suíça');
    expect(kExerciseNamePt['J74XlNf'], 'Rosca alternada sentada na bola suíça com halteres');
    expect(kExerciseNamePt['2NImIAG'], 'Rosca com halteres sentado na bola suíça e uma perna elevada');
    expect(kExerciseNamePt['LMGXZn8'], 'Tríceps testa declinado com barra e pegada fechada');
    expect(kExerciseNamePt['banded-pallof-press'], 'Pallof press com elástico');
    expect(kExerciseNamePt['single-arm-dumbbell-tricep-extension'], 'Tríceps francês unilateral com halter');
    expect(kExerciseNamePt['reverse-grip-bench-press'], 'Supino reto com barra e pegada invertida');
    expect(kExerciseNamePt['seal-jack'], 'Polichinelo com palmas à frente do peito');
    expect(kExerciseNamePt['incline-dumbbell-curl'], 'Rosca inclinada com halteres');
    expect(kExerciseNamePt['neutral-grip-pull-up'], 'Barra fixa com pegada neutra');
    expect(kExerciseNamePt['worlds-greatest-stretch'], 'Alongamento em avanço com rotação do tronco');
    expect(kExerciseNamePt['assault-bike'], 'Air bike');
  });

  test('JM press identifies the triceps movement and barbell', () {
    expect(kExerciseNamePt['ZsiqXYa'], 'JM press com barra');
  });

  test('overhead kettlebell triceps extension preserves the overhead position', () {
    expect(
      kExerciseNamePt['kettlebell-overhead-tricep-extension'],
      'Extensão de tríceps acima da cabeça com kettlebell',
    );
  });

  test('prone reverse fly identifies body position, bench and dumbbells', () {
    expect(kExerciseNamePt['lying-rear-lateral-raise'], 'Crucifixo inverso de bruços no banco com halteres');
  });

  test('reverse wrist curl uses natural Portuguese word order', () {
    expect(kExerciseNamePt['LsZkfU6'], 'Rosca inversa de punho com barra');
  });

  test('language switches change display names without changing stored exercises', () {
    final before = kExercises.map((exercise) => jsonEncode(exercise.toJson())).toList();
    final idsBefore = kExercises.map((exercise) => exercise.id).toList();
    final bench = kExercises.firstWhere((e) => e.id == 'EIeI8Vf');

    setAppLanguage('en');
    expect(exerciseName(bench), 'Barbell Bench Press');
    setAppLanguage('pt');
    expect(exerciseName(bench), 'Supino reto com barra');
    setAppLanguage('es');
    expect(exerciseName(bench), 'Press de banca con barra');
    setAppLanguage('it');
    expect(exerciseName(bench), kExerciseNameIt[bench.id]);
    setAppLanguage('zh');
    expect(exerciseName(bench), kExerciseNameZh[bench.id]);
    setAppLanguage('en');

    expect(kExercises.map((exercise) => jsonEncode(exercise.toJson())).toList(), before);
    expect(kExercises.map((exercise) => exercise.id).toList(), idsBefore);
  });

  test('Portuguese names and aliases have unique production sortedKey owners', () {
    final ids = kExercises.map((exercise) => exercise.id).toSet();
    final owners = <String, Set<String>>{};
    void add(String value, String id) => owners.putIfAbsent(sortedKey(value), () => <String>{}).add(id);
    for (final entry in kExerciseNamePt.entries) {
      add(entry.value, entry.key);
    }
    for (final entry in kExerciseAliasesPt.entries) {
      expect(ids, contains(entry.key));
      for (final alias in entry.value) {
        expect(alias.trim(), isNotEmpty);
        add(alias, entry.key);
      }
    }
    expect(owners.values.where((ids) => ids.length > 1), isEmpty);
  });
}
