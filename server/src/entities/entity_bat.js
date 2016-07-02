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
	}

	getMobType() {
		return "Rat";
	}
}

export default EntityRat;