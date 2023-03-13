late String player;
List<Trigger> triggers = [];
late Map game;

abstract class Effect {
  abstract final Function effect;
  void _activeTriggers() {
    triggers
        //only keep effects that trigger on this type
        .where((trigger) => trigger.on == runtimeType)
        //then trigger they effects
        .forEach((trigger) => trigger.effect(this));
    triggers.removeWhere((trigger) {
      try {
        //ignore:undefined_getter
        return trigger.times == 0 ? true : false;
      } catch (e) {
        return false;
      }
    });
  }
}

abstract class Trigger extends Effect {
  abstract final Type on;
}

//effects

class Heal extends Effect {
  Heal(this.amount) {
    _activeTriggers();
    effect(amount);
  }

  int amount;

  @override
  Function get effect => (int amount) {
        int i = game[player]!["hp"];
        game[player]!["hp"] = i + amount;
      };
}

class Damage extends Effect {
  Damage(this.amount) {
    _activeTriggers();
    effect(amount);
  }

  int amount;

  @override
  Function get effect => (int amount) {
        int i = game[player]!["hp"];
        game[player]!["hp"] = i - amount;
      };
}

//triggers

class Armor extends Trigger {
  Armor({required this.reduction, required this.times});

  int reduction;
  int times;

  @override
  Type get on => Damage;

  @override
  Function get effect => (Damage d) => d.amount -= reduction;
}
