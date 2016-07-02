import EntityMob from "./entity_mob";

class EntityDwarf extends EntityMob {
	constructor(game, room, x, y) {
		super(game, room, x, y);

		this.damage = 2;
		this.critChance = 0.2;
		this.critMultiplier = 2;
		this.damageTick = 20;

		this.health = 6;

		this.name = "Dwarf";
		this.n = "";

		this.drops = {
			"shooter": {
				chance: 0.2
			},
			"projectile": {
				chance: 1,
				min: 2,
				max: 4
			}
		};

		this.xpAward = 5;
	}

	getMobType() {
		return "dwarf";
	}
}

export default EntityDwarf;