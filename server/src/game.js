import DB from "./db";
import Player from "./player";
import DungeonGenerator from "./dungeon";

import hat from "hat";
import bcrypt from "bcrypt-nodejs";
import Promise from "bluebird";

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

			DB.models.User.findOne({ name: new RegExp(`^${username}$`, "i") }).then(user => {
				if (!user) {
					return reject("incorrect_login");
				}

				if (!bcrypt.compareSync(password, user.password)) {
					return reject("incorrect_login");
				}

				console.log(`Player ${user.name} connecting`);

				let token = hat();
				let player = new Player(Game, user.name, token, user._id);
				player.room = Game.spawnRoom;
				player.x = Game.rooms[Game.spawnRoom].x + Game.rooms[Game.spawnRoom].spawnX;
				player.y = Game.rooms[Game.spawnRoom].y + Game.rooms[Game.spawnRoom].spawnY;

				Game.players.push(player);

				Game.broadcast("online_users", Game.players.length);

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
			player.notify();
		});
	},

	broadcastToAllBut(but, type, data) {
		Game.players.forEach(player => {
			if (but.toLowerCase() === player.name.toLowerCase()) return;

			player.addEvent(type, data);
			player.notify();
		});
	},

	roomToJSON(room) {
		return {
			id: room.id,
			x: room.x,
			y: room.y,
			width: room.width,
			height: room.height,
			spawn: room.spawn,
			spawnX: room.spawnX,
			spawnY: room.spawnY,
			type: room.type,
			name: room.name,
			touching: room.touching,
			touchingHubs: room.touchingHubs,
			touchingRegular: room.touchingRegulars,
			touchingHalls: room.touchingHalls
		};
	}
};

export default Game;