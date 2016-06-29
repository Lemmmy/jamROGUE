import DB from "../db";
import Game from "../game";
import _ from "lodash";

export default app => {
	app.get("/players", (req, res) => {
		let out = [];

		DB.models.User.findAll().then(results => {
			res.json({
				ok: true,
				count: out.length,
				players: _.map(results => { return results.name; })
			});
		});
	});
};