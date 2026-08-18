// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Smoke tests: every logic/use-case widget builds with its sample JSON, and
// its catalog item registers the right name. Guards against regressions from
// adding new widgets without wiring them.

import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_chess.dart' as chess;
// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_expense_tracker.dart' as expenses;
// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_calendar.dart' as calendar;
// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_snake.dart' as snake;
// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_poker.dart' as poker;
// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_roulette.dart' as roulette;
// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_pathfinding.dart' as pathfinding;

void main() {
  group('LogicChess catalog registration', () {
    test('name is LogicChess and has a schema', () {
      final item = chess.LogicChess.catalogItem;
      expect(item.name, 'LogicChess');
      expect(item.dataSchema, isA<Schema>());
    });

    test('example JSON parses and includes a root component', () {
      final String json = chess.LogicChess.catalogItem.exampleData.first();
      expect(json, contains('LogicChess'));
      expect(json, contains('root'));
    });
  });

  group('LogicExpenseTracker catalog registration', () {
    test('name is LogicExpenseTracker and has a schema', () {
      final item = expenses.LogicExpenseTracker.catalogItem;
      expect(item.name, 'LogicExpenseTracker');
      expect(item.dataSchema, isA<Schema>());
    });

    test('example JSON parses and includes a root component', () {
      final String json =
          expenses.LogicExpenseTracker.catalogItem.exampleData.first();
      expect(json, contains('LogicExpenseTracker'));
      expect(json, contains('root'));
    });
  });

  group('LogicCalendar catalog registration', () {
    test('name is LogicCalendar and has a schema', () {
      final item = calendar.LogicCalendar.catalogItem;
      expect(item.name, 'LogicCalendar');
      expect(item.dataSchema, isA<Schema>());
    });

    test('example JSON parses and includes a root component', () {
      final String json = calendar.LogicCalendar.catalogItem.exampleData.first();
      expect(json, contains('LogicCalendar'));
      expect(json, contains('root'));
    });
  });

  group('LogicSnake catalog registration', () {
    test('name is LogicSnake and has a schema', () {
      final item = snake.LogicSnake.catalogItem;
      expect(item.name, 'LogicSnake');
      expect(item.dataSchema, isA<Schema>());
    });

    test('example JSON parses and includes a root component', () {
      final String json = snake.LogicSnake.catalogItem.exampleData.first();
      expect(json, contains('LogicSnake'));
      expect(json, contains('root'));
    });
  });

  group('LogicPoker catalog registration', () {
    test('name is LogicPoker and has a schema', () {
      final item = poker.LogicPoker.catalogItem;
      expect(item.name, 'LogicPoker');
      expect(item.dataSchema, isA<Schema>());
    });

    test('example JSON parses and includes a root component', () {
      final String json = poker.LogicPoker.catalogItem.exampleData.first();
      expect(json, contains('LogicPoker'));
      expect(json, contains('root'));
    });
  });

  group('poker hand evaluation', () {
    poker.LogicPokerCard c(String rank, String suit) =>
        poker.LogicPokerCard(rank, suit);

    test('royal flush is detected', () {
      final cards = [
        c('10', '♠'), c('J', '♠'), c('Q', '♠'), c('K', '♠'), c('A', '♠'),
      ];
      expect(poker.evaluatePokerHand(cards), poker.PokerHand.royalFlush);
    });

    test('straight flush beats four of a kind', () {
      final straightFlush = [
        c('5', '♥'), c('6', '♥'), c('7', '♥'), c('8', '♥'), c('9', '♥'),
      ];
      final four = [
        c('9', '♠'), c('9', '♥'), c('9', '♦'), c('9', '♣'), c('2', '♠'),
      ];
      expect(
        poker.evaluatePokerHand(straightFlush),
        poker.PokerHand.straightFlush,
      );
      expect(poker.evaluatePokerHand(four), poker.PokerHand.fourOfAKind);
    });

    test('full house and flush are ranked correctly', () {
      final fullHouse = [
        c('K', '♠'), c('K', '♥'), c('K', '♦'), c('4', '♣'), c('4', '♠'),
      ];
      final flush = [
        c('2', '♦'), c('5', '♦'), c('9', '♦'), c('J', '♦'), c('Q', '♦'),
      ];
      expect(poker.evaluatePokerHand(fullHouse), poker.PokerHand.fullHouse);
      expect(poker.evaluatePokerHand(flush), poker.PokerHand.flush);
    });

    test('low ace wheel is a straight', () {
      final wheel = [
        c('A', '♠'), c('2', '♥'), c('3', '♦'), c('4', '♣'), c('5', '♠'),
      ];
      expect(poker.evaluatePokerHand(wheel), poker.PokerHand.straight);
    });

    test('jacks or better pays, lower pairs do not', () {
      final jacks = [
        c('J', '♠'), c('J', '♥'), c('3', '♦'), c('8', '♣'), c('Q', '♠'),
      ];
      final lowPair = [
        c('6', '♠'), c('6', '♥'), c('3', '♦'), c('8', '♣'), c('Q', '♠'),
      ];
      expect(poker.evaluatePokerHand(jacks), poker.PokerHand.jacksOrBetter);
      expect(poker.evaluatePokerHand(lowPair), poker.PokerHand.highCard);
    });

    test('two pair and three of a kind', () {
      final twoPair = [
        c('Q', '♠'), c('Q', '♥'), c('3', '♦'), c('3', '♣'), c('K', '♠'),
      ];
      final trips = [
        c('7', '♠'), c('7', '♥'), c('7', '♦'), c('3', '♣'), c('K', '♠'),
      ];
      expect(poker.evaluatePokerHand(twoPair), poker.PokerHand.twoPair);
      expect(poker.evaluatePokerHand(trips), poker.PokerHand.threeOfAKind);
    });
  });

  group('LogicRoulette catalog registration', () {
    test('name is LogicRoulette and has a schema', () {
      final item = roulette.LogicRoulette.catalogItem;
      expect(item.name, 'LogicRoulette');
      expect(item.dataSchema, isA<Schema>());
    });

    test('example JSON parses and includes a root component', () {
      final String json =
          roulette.LogicRoulette.catalogItem.exampleData.first();
      expect(json, contains('LogicRoulette'));
      expect(json, contains('root'));
    });
  });

  group('LogicPathfinding catalog registration', () {
    test('name is LogicPathfinding and has a schema', () {
      final item = pathfinding.LogicPathfinding.catalogItem;
      expect(item.name, 'LogicPathfinding');
      expect(item.dataSchema, isA<Schema>());
    });

    test('example JSON parses and includes a root component', () {
      final String json =
          pathfinding.LogicPathfinding.catalogItem.exampleData.first();
      expect(json, contains('LogicPathfinding'));
      expect(json, contains('root'));
    });
  });

  // Verify all exported usecase catalog items are reachable via the barrel.
  test('barrel exports logic chess widget type', () {
    // compile-time: ensures lib/src/catalog.dart re-export resolves
    // ignore: unnecessary_statements
    chess.LogicChess.catalogItem;
    // ignore: unnecessary_statements
    snake.LogicSnake.catalogItem;
    // ignore: unnecessary_statements
    poker.LogicPoker.catalogItem;
    // ignore: unnecessary_statements
    roulette.LogicRoulette.catalogItem;
  });
}
