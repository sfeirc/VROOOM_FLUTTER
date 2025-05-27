// Ceci est un test de widget Flutter de base.
//
// Pour effectuer une interaction avec un widget dans votre test, utilisez l'utilitaire WidgetTester
// du package flutter_test. Par exemple, vous pouvez envoyer des gestes de tap et de défilement.
// Vous pouvez également utiliser WidgetTester pour trouver des widgets enfants dans l'arbre de widgets,
// lire du texte et vérifier que les valeurs des propriétés des widgets sont correctes.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vrooom_lourd/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Construire notre application et déclencher une frame
    await tester.pumpWidget(const MyApp());

    // Vérifier que notre compteur commence à 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Taper sur l'icône '+' et déclencher une frame
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Vérifier que notre compteur a été incrémenté
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
