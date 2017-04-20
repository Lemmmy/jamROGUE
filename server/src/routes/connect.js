import DB from "../db";
import Game from "../game";

export default app => {
	app.post("/connect", (req, res) => {
		if (!req.body.name || !/^[a-z0-9_]{3,15}$/i.test(req.body.name)) {
			return res.json({
				ok: false,
				error: "invalid_username"
			});
		}

		if (!req.body.password) {
			return res.json({
				ok: false,
				error: "missing_password"
			});
		}

		if (!req.body.colour) {
			req.body.colour = "0";
		}

		Game.authPlayer(req.body.name, req.body.password, req.body.colour).then(player => {
			return res.json({
				ok: true,
				name: player.name,
				token: player.token
			});
		}).catch(error => {
			return res.json({
				ok: false,
				error: error.toString()
			});
		});
	});
};
