import DB from "../db";
import Game from "../game";

export default app => {
	app.post("/game/poll", (req, res) => {
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

		let events = player.getEvents();

		if (!events || (events && events.length === 0)) {
			player.pause(req, res);
		} else {
			res.json({
				ok: true,
				events: events
			});
			res.end();

			player.connected = false;
			player.disconnectedTime = new Date();
		}
	});
};