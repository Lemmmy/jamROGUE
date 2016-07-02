import Game from "../game";

import _ from "lodash";

export default app => {
	app.post("/game/entity/:id/interact", (req, res) => {
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

		if (!player.alive) {
			return res.json({
				ok: false,
				error: "dead"
			});
		}

		let entity = _.find(Game.entities, { id: req.params.id });

		if (!entity) {
			return res.json({
				ok: false,
				error: "no_entity"
			});
		}

		entity.interact(player);

		res.json({
			ok: true
		});
	});
};