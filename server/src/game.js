import DB from "./db";
import Player from "./player";
import DungeonGenerator from "./dungeon";

import hat from "hat";
import bcrypt from "bcrypt-nodejs";

import _ from "lodash";

let Game = {
	lastPollID: 0,
	rooms: [],
	spawnRoom: 0,
	dungeonID: hat(36),

	init() {
		return new Promise(resolve => {
			Game.players = [];

			DungeonGenerator.generate().then(rooms => {
				Game.rooms = rooms;

				let bigRooms = Game.rooms.filter(r => { return r.type === "hub" });
				let spawnRoom = _.sample(bigRooms);

				Game.spawnRoom = spawnRoom.id;
				Game.rooms[spawnRoom.id].spawn = true;
				Game.rooms[spawnRoom.id].spawnX = _.random(3, spawnRoom.width - 3);
				Game.rooms[spawnRoom.id].spawnY = _.random(3, spawnRoom.height - 3);

				resolve();
			});
		});
	},

	authPlayer(username, password) {
		return new Promise((resolve, reject) => {
			for (var i = 0; i < Game.players.length; i++) {
				if (Game.players[i].name.toLowerCase() === username.toLowerCase()) {
					return reject("already_logged_in");
				}
			}

			DB.r.table("users").filter(user => {
				return user("name").match(`(?i)^${username}$`);
			}).limit(1).run().then(results => {
				if (results.length !== 1) {
					return reject("incorrect_login");
				}

				let user = results[0];

				if (!bcrypt.compareSync(password, user.password)) {
					return reject("incorrect_login");
				}

				let token = hat();
				let player = new Player(Game, user.name, token);
				player.room = Game.spawnRoom;
				player.x = Game.rooms[Game.spawnRoom].x + Game.rooms[Game.spawnRoom].spawnX;
				player.y = Game.rooms[Game.spawnRoom].y + Game.rooms[Game.spawnRoom].spawnY;

				Game.players.push(player);

				Game.broadcast("online_users", Game.players.length);
				player.addEvent("spawn", _.merge({ dungeonID: Game.dungeonID, players: _.map(Game.players, p => { return p.toJSON(); }) }, player.toJSON()));
				player.addEvent("room", Game.rooms[player.room]);

				Game.broadcastToAllBut(player.name, "join", player.toJSON());

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
	},

	broadcast(type, data) {
		Game.players.forEach(player => {
			player.addEvent(type, data);
			player.notify()
		});
	},

	broadcastToAllBut(but, type, data) {
		Game.players.forEach(player => {
			if (but.toLowerCase() === player.name.toLowerCase()) return;

			player.addEvent(type, data);
			player.notify()
		});
	}
};

export default Game;