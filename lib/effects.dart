late String player;
List<Trigger> triggers = [];
late Map game;

abstract class Effect {
  abstract final Function effect;
  void _activeTriggers() {
    //remove depleted triggers
    triggers
        .removeWhere((trigger) => trigger.duration.isBefore(DateTime.now()));
    triggers
        //only keep effects that trigger on this type
        .where((trigger) => trigger.on == runtimeType)
        //then trigger they effects
        .forEach((trigger) => trigger.effect(this));
  }
}

abstract class Trigger extends Effect {
  abstract final Type on;
  abstract DateTime duration;
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
        int i = game["hp"];
        game["hp"] = i + amount;
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
        int i = game["hpEnemy"];
        game["hpEnemy"] = i - amount;
      };
}

//triggers

class Armor extends Trigger {
  Armor({required this.reduction, int? duration})
      : duration = DateTime.now().add(Duration(seconds: duration ?? 9999));

  int reduction;
  @override
  DateTime duration;

  @override
  Type get on => Damage;

  @override
  Function get effect => (Damage d) => d.amount -= reduction;
}
