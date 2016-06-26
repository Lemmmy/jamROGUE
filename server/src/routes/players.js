import DB from "../db";
import Game from "../game";

export default app => {
	app.get("/players", (req, res) => {
		let out = [];

		DB.r.table("users").run().then(results => {
			results.forEach(player => {
				out.push({
					name: player.name
				});
			});

			res.json({
				ok: true,
				count: out.length,
				players: out
			});
		});
	});
};