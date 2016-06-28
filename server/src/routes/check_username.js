import DB from "../db";

export default app => {
	app.get("/register/check/:name", (req, res) => {
		if (!req.params.name || !/^[a-z0-9_]{3,15}$/i.test(req.params.name)) {
			return res.json({
				ok: false,
				error: "invalid_username"
			});
		}

		DB.models.User.count({ name: new RegExp(`^${req.params.name}$`, "i") }).then(count => {
			res.json({
				ok: true,
				available: count === 0
			});
		}).catch(error => {
			console.error(error);

			res.json({
				ok: false,
				error: "server_error"
			});
		});
	});
};