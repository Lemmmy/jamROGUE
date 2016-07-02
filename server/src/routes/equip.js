import Game from "../game";
import Item from "../item";
import CCColours from "../colours";

import _ from "lodash";

export default app => {
	app.post("/game/equip", (req, res) => {
		if (!req.body.token) {
			return res.json({
				ok: false,
				error: "missing_token"
			});
		}

		let player = Game.getPlayerByToken(req.body.token);

		if (!player) {
			return res.json({
				ok: false,
				error: "invalid_token"
			});
		}

		if (!req.body.item) {
			return res.json({
				ok: false,
				error: "missing_item"
			});
		}

		if (!player.alive) {
			return res.json({
				ok: false,
				error: "dead"
			});
		}

		let item = parseInt(req.body.item);

		if (item >= player.inventory.length) {
			return res.json({
				ok: false,
				error: "no_item"
			});
		}

		if (player.inventory[item].item.type === "consumable") {
			let i = player.inventory[item];

			if (i.item.subType && i.item.subType === "healing") {
				player.health = Math.min(player.health + i.item.heal, player.level + 4);
				player.user.health = player.health;
				player.user.save();

				player.addEvent("server_message", {
					fancy: true,
					text: "You " + (i.verb || "ate") + " " + (i.count && i.count > 1 ? ("a" + (i.item.rarity ? (/^[aeiou]/i.test(i.item.rarity) ? "n" : "") : (/^[aeiou]/i.test(i.item.name) ? "n" : ""))) : "the") + " &" + CCColours.colourToHex(i.item.rarity ? i.item.colour : CCColours.white) + (i.item.rarity ? i.item.rarity + " " : "") + i.item.name + "&0" + "."
				});

				player.addEvent("damage", {
					health: player.health
				});

				if (i.count > 1) {
					i.count--;
				} else {
					player.inventory.splice(item, 1);
				}
			}
		} else {
			player.inventory = _.map(player.inventory, (i, j) => {
				i.equipped = j == item;

				return i;
			});

			let equippedItem = player.inventory[item];

			player.addEvent("server_message", {
				fancy: true,
				text: "You equipped " + (equippedItem.count && equippedItem.count > 1 ? ("a" + (equippedItem.item.rarity ? (/^[aeiou]/i.test(equippedItem.item.rarity) ? "n" : "") : (/^[aeiou]/i.test(equippedItem.item.name) ? "n" : ""))) : "the") + " &" + CCColours.colourToHex(equippedItem.item.rarity ? equippedItem.item.colour : CCColours.white) + (equippedItem.item.rarity ? equippedItem.item.rarity + " " : "") + equippedItem.item.name + "&0" + "."
			});
		}

		player.saveInventory();
		player.updateInventory();
		player.notify();

		res.json({
			ok: true
		});
	});
};