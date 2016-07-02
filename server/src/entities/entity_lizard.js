import EntityMob from "./entity_mob";

class EntityLizard extends EntityMob {
	constructor(game, room, x, y) {
		super(game, room, x, y);

		this.damage = 2;
		this.critChance = 0.2;
		this.critMultiplier = 2;
		this.damageTick = 30;

		this.health = 8;

		this.name = "Lizard";
		this.n = "";

		this.drops = {
			"consumable": {
				chance: 1,
				min: 1,
				max: 2
			}
		};

		this.xpAward = 10;
	}

	getMobType() {
		return "lizard";
	}
}

export default EntityLizard;