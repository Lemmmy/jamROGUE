import EntityMob from "./entity_mob";

class EntitySerpent extends EntityMob {
	constructor(game, room, x, y) {
		super(game, room, x, y);

		this.damage = 3;
		this.critChance = 0.1;
		this.critMultiplier = 2;
		this.damageTick = 25;

		this.health = 7;

		this.name = "Serpent";
		this.n = "";

		this.drops = {
			"consumable": {
				chance: 1,
				min: 2,
				max: 4
			}
		};

		this.xpAward = 14;
	}

	getMobType() {
		return "serpent";
	}
}

export default EntitySerpent;