import config from "./config.json";

require("console-stamp")(console);

import DB from "./db";
import Server from "./server";
import Game from "./game";

DB.init(config).then(() => {
	console.log("[DB] ready");

	Server.init(config).then(() => {
		Game.init(config).then(() => {
			console.log("ready");
		});
	});
})