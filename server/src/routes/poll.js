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

		let time = req.query.time || 0;
		let event = player.nextEvent(time);
		let pollID = Game.lastPollID++;

		if (!event) {
			player.pause(time, req, res, pollID);
		} else {
			res.json({
				ok: true,
				event: event
			});
			res.end();

			player.connected = false;
			player.disconnectedTime = new Date();
		}
	});
};