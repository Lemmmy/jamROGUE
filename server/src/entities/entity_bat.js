import EntityMob from "./entity_mob";

class EntityBat extends EntityMob {
	constructor(game, room, x, y) {
		super(game, room, x, y);

		this.damage = 1;
		this.critChance = 0;
		this.critMultiplier = 1;
		this.damageTick = 12;

		this.health = 2;

		this.name = "Bat";
		this.n = "";

		this.drops = {
			"throwable": {
				chance: 0.2
			},
			"projectile": {
				chance: 0.2
			}
		};

		this.xpAward = 2;
	}

	getMobType() {
		return "bat";
	}
}

export default EntityBat;