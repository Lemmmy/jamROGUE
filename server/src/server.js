import express from "express";
import bodyParser from "body-parser";
import path from "path";
import fs from "fs";
import Promise from "bluebird";

let Server = {
	init(config) {
		return new Promise((resolve, reject) => {
			let app = express();

			app.enable("trust proxy");
			app.disable("x-powered-by");
			app.disable("etag");

			app.all("*", (req, res, next) => {
				delete req.headers["content-encoding"]
				res.header("X-Robots-Tag", "none");
				res.header("Content-Type", "application/json");
				res.header("Access-Control-Allow-Origin", "*");

				next();
			});

			app.use(bodyParser.urlencoded({ extended: false }));
			app.use(bodyParser.json());

			console.log("[Webserver] Loading routes");

			try {
				let routePath = path.join(__dirname, "routes");

				fs.readdirSync(routePath).forEach(file => {
					if (path.extname(file).toLowerCase() !== ".js") {
						return;
					}

					try {
						require("./routes/" + file).default(app);
					} catch (error) {
						console.error("[Webserver] Error loading route " + file + ":");
						console.error(error.stack);

						reject();
					}
				});
			} catch (error) {
				console.error("[Webserver] Error finding routes:");
				console.error(error.stack);

				reject();
			}

			fs.unlink(config.listen, () => {
				app.listen(config.listen, () => {
					console.log("[Webserver] Ready");

					resolve();
				}).on("error", err => {
					console.log(err);
				});
			});

			Server.app = app;
		});
	}
};

export default Server;