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

		let item = parseInt(req.body.item);

		if (item >= player.inventory.length) {
			return res.json({
				ok: false,
				error: "no_item"
			});
		}

		player.inventory = _.map(player.inventory, (i, j) => {
			i.equipped = j == item;

			return i;
		});

		let equippedItem = player.inventory[item];

		player.saveInventory();
		player.addEvent("server_message", {
			fancy: true,
			text: "You equipped " + (equippedItem.count && equippedItem.count > 1 ? ("a" + (equippedItem.item.rarity ? (/^[aeiou]/i.test(equippedItem.item.rarity) ? "n" : "") : (/^[aeiou]/i.test(equippedItem.item.name) ? "n" : ""))) : "the") + " &" + CCColours.colourToHex(equippedItem.item.rarity ? equippedItem.item.colour : CCColours.white) + (equippedItem.item.rarity ? equippedItem.item.rarity + " " : "") + equippedItem.item.name + "&0" + "."
		});
		player.updateInventory();

		player.notify();

		res.json({
			ok: true
		});
	});
};