import 'power_up_pool.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class Result {
  Result(
      {required this.name,
      required this.order,
      required this.cost,
      required this.costAccumulate});
  String name;
  int? order;
  int cost;
  int costAccumulate;
}

class PowerUpCalculator with ChangeNotifier {
  final PowerUpPool powerUpPool;
  PowerUpCalculator(this.powerUpPool);

  int _getCostOne(int basePrice, int currentLevels, {int idx = 0}) {
    int price = 0;
    for (int i = 0; i < currentLevels; ++i) {
      price += basePrice * (i + 1) * (idx + 10) ~/ 10;
      ++idx;
    }
    return price;
  }

  List<int> _getCost(List<int> basePrices, List<int> currentLevels) {
    assert(basePrices.length == currentLevels.length);
    List<int> prices = [];
    int idx = 0;
    for (List<int> pair in IterableZip([basePrices, currentLevels])) {
      prices.add(_getCostOne(pair[0], pair[1], idx: idx));
      idx += pair[1];
    }
    return prices;
  }

  int _getInflation(int basePrice, int currentLevel) =>
      basePrice * currentLevel * (currentLevel + 1) ~/ 20;

  List<Result> get getResult {
    List<String> itemNames = [
      for (String e in powerUpPool.powerUpLocalStorage.itemInfos.keys)
        if (powerUpPool.powerUps[e]! > 0) e
    ];

    itemNames.sort(((a, b) {
      int da = _getInflation(
              powerUpPool.powerUpLocalStorage.itemInfos[a]!.price,
              powerUpPool.powerUps[a]!) *
          powerUpPool.powerUps[b]!;
      int db = _getInflation(
              powerUpPool.powerUpLocalStorage.itemInfos[b]!.price,
              powerUpPool.powerUps[b]!) *
          powerUpPool.powerUps[a]!;
      return db.compareTo(da);
    }));

    List<String> names = List<String>.from(itemNames);
    List<int?> orders = [1];

    for (int i = 1; i < names.length; ++i) {
      int da = _getInflation(
              powerUpPool.powerUpLocalStorage.itemInfos[names[i - 1]]!.price,
              powerUpPool.powerUps[names[i - 1]]!) *
          powerUpPool.powerUps[names[i]]!;
      int db = _getInflation(
              powerUpPool.powerUpLocalStorage.itemInfos[names[i]]!.price,
              powerUpPool.powerUps[names[i]]!) *
          powerUpPool.powerUps[names[i - 1]]!;
      if (da > db) {
        orders.add(i + 1);
      } else {
        orders.add(null);
      }
    }

    List<int> costs = _getCost([
      for (String name in names)
        powerUpPool.powerUpLocalStorage.itemInfos[name]!.price
    ], [
      for (String name in names) powerUpPool.powerUps[name]!
    ]);
    List<int> costsAccumulate = [];
    for (int cost in costs) {
      if (costsAccumulate.isEmpty) {
        costsAccumulate.add(cost);
      } else {
        costsAccumulate.add(costsAccumulate.last + cost);
      }
    }
    List<Result> results = [];
    for (int i = 0; i < names.length; ++i) {
      results.add(Result(
        name: names[i],
        order: orders[i],
        cost: costs[i],
        costAccumulate: costsAccumulate[i],
      ));
    }
    return results;
  }
}
