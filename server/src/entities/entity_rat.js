import EntityMob from "./entity_mob";

class EntityRat extends EntityMob {
	constructor(game, room, x, y) {
		super(game, room, x, y);

		this.damage = 1;
		this.critChance = 0;
		this.critMultiplier = 1;
		this.damageTick = 15;

		this.health = 2;

		this.name = "Rat";
		this.n = "";

		this.drops = {
			"Poop": {
				chance: 1,
				min: 1,
				max: 3
			},
			"throwable": {
				chance: 0.2
			},
			"projectile": {
				chance: 0.2
			}
		};
	}

	getMobType() {
		return "rat";
	}
}

export default EntityRat;