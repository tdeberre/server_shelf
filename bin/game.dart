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

  late final String enemy;
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
      ..._state,
      ...{
        "hpEnemy": enemyState["hp"],
        "handEnemy": enemyState["hand"].length,
        "deckEnemy": enemyState["deck"].length,
        "heatEnemy": enemyState["heat"],
        "triggersEnemy": enemyState["triggers"]
      }
    };
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

  void play(String card) async {
    if (state["hand"].contains(card)) {
      final data = File("bin/data/cards.json").readAsStringSync();
      final cards = jsonDecode(data);
      final effect = cards[card]["func"];
      _state = await gameEval(effect, player, _state);
      sendNewState();
    }
  }

  sendNewState() {
    print(jsonEncode(state));
    socket.write(jsonEncode(state));
    print("state");
    players
        .firstWhere((e) => e.player == enemy)
        .socket
        .write(jsonEncode(enemyState));
    print("enemy state");
  }
}

List<Player> players = [];
