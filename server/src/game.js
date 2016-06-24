import DB from "./db";
import Player from "./player";

import hat from "hat";
import bcrypt from "bcrypt-nodejs";

let Game = {
	lastPollID: 0,

	init() {
		return new Promise(resolve => {
			Game.players = [];

			resolve();
		});
	},

	authPlayer(username, password) {
		return new Promise((resolve, reject) => {
			for (var i = 0; i < Game.players.length; i++) {
				if (Game.players[i].name.toLowerCase() === username.toLowerCase()) {
					return reject("already_logged_in");
				}
			}

			DB.r.table("users").filter({ name: username }).limit(1).run().then(results => {
				if (results.length !== 1) {
					return reject("incorrect_login");
				}

				let user = results[0];

				if (!bcrypt.compareSync(password, user.password)) {
					return reject("incorrect_login");
				}

				let token = hat();
				let player = new Player(Game, user.name, token);

				Game.players.push(player);

				resolve(player);
			});
		});
	},

	getPlayerByToken(token) {
		for (var i = 0; i < Game.players.length; i++) {
			if (Game.players[i].token === token) {
				return Game.players[i];
			}
		}

		return null;
	}
};

export default Game;