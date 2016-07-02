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

		if (req.body.time) {
			if (player.lastMove > parseFloat(req.body.time)) {
				return res.json({
					ok: true,
					moved: false
				});
			}

			player.lastMove = parseFloat(req.body.time);
		}

		if (!player.alive) {
			return res.json({
				ok: false,
				error: "dead"
			});
		}

		player.move(parseInt(req.body.x), parseInt(req.body.y));

		res.json({
			ok: true,
			moved: true
		});
	});
};