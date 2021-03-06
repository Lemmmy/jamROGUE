import Entity from "./entity";
import Item from "../item";
import CCColours from "../colours";

import _ from "lodash";

class EntityChest extends Entity {
	constructor(game, room, x, y, locked = false) {
		super(game, room, x, y);

		this.locked = locked;
		this.looted = false;
	}

	inspectEntity() {
		return "It's a " + (this.locked ? "locked " : "") + "chest.";
	}

	interact(player) {
		if (this.Game.playerDistancePoint(player, this.x, this.y) < 2) {
			if (this.looted) {
				player.addEvent("server_message", { text: "Looks like it's already been looted.", colour: CCColours.red });
				player.notify();

				return;
			}

			let key;

			if (this.locked) {
				key = _.find(player.inventory, i => { return i.item instanceof Item ? (i.item.serialize().subType && i.item.serialize().subType === "chest_key") : i.item.subType === "chest_key"; });
			}

			if (!key && this.locked) {
				let equippedItem = _.find(player.inventory, "equipped");
				if (!equippedItem) {
					player.addEvent("server_message", {
						text: `You swing your hands at the chest but nothing happens.`,
						colour: CCColours.red
					});

					return player.notify();
				}

				let itemName = (equippedItem.count && equippedItem.count > 1 ?
						("a" + (equippedItem.item.rarity ? (/^[aeiou]/i.test(equippedItem.item.rarity) ? "n" : "") :
						(/^[aeiou]/i.test(equippedItem.item.name) ? "n" : ""))) : "the") +
						" &" + CCColours.colourToHex(equippedItem.item.rarity ? equippedItem.item.colour : CCColours.white) +
						(equippedItem.item.rarity ? equippedItem.item.rarity + " " : "") + equippedItem.item.name;

				if (equippedItem.item.type !== "melee") {
					player.addEvent("server_message", {
						text: `&eYou swing ${itemName}&e at the chest but nothing happens.`,
						fancy: true
					});

					return player.notify();
				}

				player.addEvent("server_message", {
					text: `&eYou swing ${itemName}&e at the chest, and it broke.`,
					fancy: true
				});
				key = equippedItem;
			}


			if ((this.locked && key) || !this.locked) {
				let r = Math.random();
				let type = r < 0.25 ? "melee" : r < 0.4 ? "projectile" : r < 0.8 ? "consumable" : "shooter";
				let item = Item.randomItem(type, player.level);

				if (this.locked && key.item.type === "melee" && Math.random() >= 0.5) {
					player.inventory.splice(player.inventory.indexOf(key), 1);
					player.updateInventory();
					player.saveInventory();
					return player.notify();
				}

				if (player.addToInventory(item, this.locked ? 1 : 0)) {
					if (this.locked) {
						player.inventory.splice(player.inventory.indexOf(key), 1);
					}

					this.looted = true;
					this.locked = false;

					setTimeout(() => {
						this.looted = false;
						this.locked = Math.random() >= 0.5;
					}, _.random(40, 120) * 1000);

					player.addEvent("server_message", {
						fancy: true,
						text: "You found " + ("a" + (item.rarity ? (/^[aeiou]/i.test(item.rarity.name) ? "n" : "") : (/^[aeiou]/i.test(item.item.name) ? "n" : ""))) + " &" + CCColours.colourToHex(item.rarity ? item.rarity.colour : CCColours.white) + (item.rarity ? item.rarity.name + " " : "") + item.item.name + "&0" + "."
					});

					player.updateInventory();
					player.saveInventory();
				} else {
					player.addEvent("server_message", { text: "You don't have room for that. ", colour: CCColours.red });
				}
			} else {
				player.addEvent("server_message", { text: "It's locked - you need a key for this.", colour: CCColours.red });
			}
		} else {
			player.addEvent("server_message", { text: "You can't " + (this.Game.playerDistancePoint(player, this.x, this.y) < 4 ? "quite " : "") + "reach that.", colour: CCColours.red });
		}

		player.notify();
	}

	serialize() {
		return _.merge(super.serialize(), {
			locked: this.locked || false
		});
	}

	getType() {
		return "Chest";
	}
}

export default EntityChest;
