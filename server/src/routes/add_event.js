import DB from "../db";
import Game from "../game";

export default app => {
	app.post("/add_event", (req, res) => {
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

		player.addEvent(req.body.type, req.body.data);
		player.notify();

		res.json({
			ok: true
		});
	});
};