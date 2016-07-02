import Game from "../game";
import Item from "../item";

import _ from "lodash";

export default app => {
	app.post("/game/respawn", (req, res) => {
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

		if (player.alive) {
			return res.json({
				ok: false,
				error: "not_dead"
			});
		}

		player.alive = true;
		player.health = player.level + 4;
		player.room = Game.spawnRoom;
		player.x = Game.rooms[Game.spawnRoom].x + Game.rooms[Game.spawnRoom].spawnX;
		player.y = Game.rooms[Game.spawnRoom].y + Game.rooms[Game.spawnRoom].spawnY;

		player.user.alive = true;
		player.user.health = player.level + 4;
		player.user.save();

		player.spawn();
		player.notify();

		Game.broadcastToAllBut(player.name, "move", {
			player: player.name,
			x: player.x,
			y: player.y,
			room: player.room
		});

		res.json({
			ok: true
		});
	});
};