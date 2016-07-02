import Entity from "./entity";
import Item from "../item";
import CCColours from "../colours";

import _ from "lodash";

class EntityDroppedItem extends Entity {
	constructor(game, room, x, y, item) {
		super(game, room, x, y);

		this.item = item;
	}

	inspectEntity() {
		console.log(this.item);
		return this.item ? (this.item instanceof Item ? this.item.serialize().description : this.item.description) : "";
	}

	interact(player) {
		if (this.Game.playerDistancePoint(player, this.x, this.y) < 2) {
			if (player.addToInventory(this.item)) {
				let item = this.item instanceof Item ? this.item.serialize() : this.item;

				player.addEvent("server_message", {
					fancy: true,
					text: "You picked up " + ("a" + (item.rarity ? (/^[aeiou]/i.test(item.rarity) ? "n" : "") : (/^[aeiou]/i.test(item.name) ? "n" : ""))) + " &" + CCColours.colourToHex(item.rarity ? item.colour : CCColours.white) + (item.rarity ? item.rarity + " " : "") + item.name + "&0" + "."
				});

				player.updateInventory();
				player.saveInventory();

				this.remove();
			} else {
				this.addEvent("server_message", { text: "You don't have room for that. ", colour: CCColours.red });
			}
		} else {
			player.addEvent("server_message", { text: "You can't " + (this.Game.playerDistancePoint(player, this.x, this.y) < 4 ? "quite " : "") + "reach that.", colour: CCColours.red });
		}

		player.notify();
	}

	serialize() {
		return _.merge(super.serialize(), {
			item: this.item instanceof Item ? this.item.serialize() : this.item
		});
	}

	getType() {
		return "DroppedItem";
	}
}

export default EntityDroppedItem;