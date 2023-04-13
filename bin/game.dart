import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:server/play.dart';

class Player {
  Player(
      {required this.player,
      required this.socket,
      required List<String> deck}) {
    _state["deck"] = deck;
  }

  final String player;
  final Socket socket;

  late String? enemy;
  get enemyState => players.firstWhere((e) => e.player == enemy)._state;
  //ignore:prefer_final_fields
  Map<String, dynamic> _state = {
    "hp": 100,
    "hand": [],
    "deck": [],
    "heat": 0,
    "triggers": []
  };

  Map<String, dynamic> get state {
    return {
      ...{
        "hpEnemy": enemyState["hp"],
        "handEnemy": enemyState["hand"].length,
        "deckEnemy": enemyState["deck"].length,
        "heatEnemy": enemyState["heat"],
        "triggersEnemy": enemyState["triggers"]
      },
      ..._state
    };
  }

  set state(Map<dynamic, dynamic> map) {
    map.forEach((key, value) {
      _state.containsKey(key) ? _state[key] == value : null;
    });
    _state.forEach((key, value) {
      map.remove(key);
    });
    map.forEach((key, value) {
      key != "handEnemy" && key != "deckEnemy"
          ? players
              .firstWhere((e) => e.player == enemy)
              ._state[key.substring(0, key.length - 5)] = value
          : null;
    });
  }

  void draw() {
    if (state["hand"].length < 6) {
      if (state["deck"].isNotEmpty) {
        final card = state["deck"][Random().nextInt(state["deck"].length)];
        state["deck"].remove(card);
        state["hand"].add(card);
      } else {
        state["hand"].add("autre");
      }
    }
    sendNewState();
  }

  Future<void> play(String card) async {
    if (state["hand"].contains(card)) {
      final data = File("bin/data/cards.json").readAsStringSync();
      final cards = jsonDecode(data);
      final effect = cards[card]["func"];
      state = await gameEval(effect, player, state);
      _state["hand"].remove(card);
      sendNewState();
    }
  }

  void sendNewState() {
    print("sending state : $state");
    socket.write(jsonEncode(state));
    final enemyPlayer = players.firstWhere((e) => e.player == enemy);
    enemyPlayer.socket.write(jsonEncode(enemyPlayer.state));
  }
}

List<Player> players = [];
