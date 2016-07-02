import EntityMob from "./entity_mob";

class EntityGoblin extends EntityMob {
	constructor(game, room, x, y) {
		super(game, room, x, y);

		this.damage = 1;
		this.critChance = 0.25;
		this.critMultiplier = 2;
		this.damageTick = 15;

		this.health = 5;

		this.name = "Goblin";
		this.n = "";

		this.drops = {
			"melee": {
				chance: 0.4
			},
			"throwable": {
				chance: 0.1
			},
			"projectile": {
				chance: 0.6
			}
		};
	}

	getMobType() {
		return "goblin";
	}
}

export default EntityGoblin;