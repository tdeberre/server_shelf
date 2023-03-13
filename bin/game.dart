import 'dart:io';
import 'dart:convert';
import 'dart:math';

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
    if (state['hand'].length < 6) {
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

  sendNewState() {
    print(jsonEncode(state));
    socket.write(jsonEncode(state));
    players
        .firstWhere((e) => e.player == enemy)
        .socket
        .write(jsonEncode(enemyState));
  }
}

List<Player> players = [];
