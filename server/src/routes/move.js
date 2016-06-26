import Game from "../game";

export default app => {
	app.post("/game/move", (req, res) => {
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

		if (!req.body.x || !req.body.y) {
			return res.json({
				ok: false,
				error: "missing_position"
			});
		}

		player.x = parseInt(req.body.x);
		player.y = parseInt(req.body.y);

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