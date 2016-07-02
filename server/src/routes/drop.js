import Game from "../game";
import Item from "../item";
import CCColours from "../colours";
import EntityDroppedItem from "../entities/entity_dropped_item";

import _ from "lodash";

export default app => {
	app.post("/game/drop", (req, res) => {
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

		let dropItem = player.inventory[item];

		player.addEvent("server_message", {
			fancy: true,
			text: "You dropped " + (dropItem.count && dropItem.count > 1 ? ("a" + (dropItem.rarity ? (/^[aeiou]/i.test(dropItem.rarity) ? "n" : "") : (/^[aeiou]/i.test(dropItem.name) ? "n" : ""))) : "the") + " &" + CCColours.colourToHex(dropItem.item.rarity ? dropItem.item.colour : CCColours.white) + (dropItem.item.rarity ? dropItem.item.rarity + " " : "") + dropItem.item.name + "&0" + "."
		});

		if (dropItem.count <= 1) {
			new EntityDroppedItem(Game, player.room, player.x, player.y, dropItem.item).spawn();

			player.inventory.splice(item, 1);
		} else {
			new EntityDroppedItem(Game, player.room, player.x, player.y, dropItem.item).spawn();

			player.inventory[item].count--;
		}

		player.saveInventory();
		player.updateInventory();

		player.notify();

		res.json({
			ok: true
		});
	});
};