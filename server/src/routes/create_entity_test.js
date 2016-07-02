import DB from "../db";
import Game from "../game";

import Item from "../item";
import EntityDroppedItem from "../entities/entity_dropped_item";
import EntityMob from "../entities/entity_mob";

export default app => {
	app.post("/create_item_test/:type/:x/:y", (req, res) => {
		let count = req.query.amt || 1;

		for (let i = 0; i < count; i++) {
			new EntityDroppedItem(
				Game,
				Game.spawnRoom,
				Game.rooms[Game.spawnRoom].x + Game.rooms[Game.spawnRoom].spawnX + parseInt(req.params.x),
				Game.rooms[Game.spawnRoom].y + Game.rooms[Game.spawnRoom].spawnY + parseInt(req.params.y),
				Item.randomItem(req.params.type, 30)).spawn();
		}

		res.json({ ok: true });
	});

	app.post("/create_mob_test/:x/:y", (req, res) => {
		new EntityMob(
			Game,
			Game.spawnRoom,
			Game.rooms[Game.spawnRoom].x + Game.rooms[Game.spawnRoom].spawnX + parseInt(req.params.x),
			Game.rooms[Game.spawnRoom].y + Game.rooms[Game.spawnRoom].spawnY + parseInt(req.params.y)).spawn();

		res.json({ ok: true });
	});
};