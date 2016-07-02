import hat from "hat";
import _ from "lodash";

class Entity {
	constructor(game, room, x, y) {
		this.Game = game;
		this.room = room;
		this.x = x;
		this.y = y;
		this.id = hat();
	}

	spawn() {
		_.filter(this.Game.players, p => {
			return p.room == this.room;
		}).forEach(p => {
			p.addEvent("entity_spawn", this.serialize());
			p.notify();
		});

		this.Game.entities.push(this);
	}

	getType() {
		return "Base";
	}

	serialize() {
		return {
			room: this.room,
			x: this.x,
			y: this.y,
			type: this.getType(),
			id: this.id
		};
	}

	remove() {
		_.filter(this.Game.players, p => {
			return p.room == this.room;
		}).forEach(p => {
			p.addEvent("entity_remove", this.serialize());
			p.notify();
		});

		this.Game.entities.splice(this.Game.entities.indexOf(this), 1);
	}

	move(x, y) {
		this.x = x;
		this.y = y;

		_.filter(this.Game.players, p => {
			return p.room == this.room;
		}).forEach(p => {
			p.addEvent("entity_move", this.serialize());
			p.notify();
		});
	}

	inspectEntity() {}
	interact(player) {}
	tick(time) {}
}

export default Entity;