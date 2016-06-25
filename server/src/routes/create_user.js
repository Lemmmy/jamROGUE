import DB from "../db";
import bcrypt from "bcrypt-nodejs";

export default app => {
	app.post("/register/:name", (req, res) => {
		if (!req.params.name || !/^[a-z0-9_]{3,15}$/i.test(req.params.name)) {
			return res.json({
				ok: false,
				error: "invalid_username"
			});
		}

		if(!req.body.password) {
			return res.json({
				ok: false,
				error: "missing_password"
			});
		}

		let serverError = error => {
			console.error(error);

			res.json({
				ok: false,
				error: "server_error"
			});
		};

		DB.r.table("users").filter(user => {
			return user("name").match(`(?i)^${req.params.name}$`)
		}).count().run().then(count => {
			if (count > 0) {
				return res.json({
					ok: false,
					error: "name_taken"
				});
			}

			DB.r.table("users").insert({
				name: req.params.name,
				password: bcrypt.hashSync(req.body.password)
			}).run().then(() => {
				res.json({
					ok: true
				});
			}).catch(serverError);
		}).catch(serverError);
	});
};