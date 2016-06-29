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
	stairRoom: 0,
	dungeonID: hat(36),

	init() {
		return new Promise(resolve => {
			Game.players = [];

			DungeonGenerator.generate().then(rooms => {
				Game.rooms = rooms;

				let bigRooms = Game.rooms.filter(r => { return r.type === "hub"; });

				let spawnRoom;

				Game.rooms.forEach(room => {
					if (room.type !== "hub") return;

					if (!spawnRoom) {
						spawnRoom = room;
						return;
					}

					if (spawnRoom.x > room.x) {
						spawnRoom = room;
					}
				});

				Game.spawnRoom = spawnRoom.id;
				Game.rooms[spawnRoom.id].subType = "spawn";
				Game.rooms[spawnRoom.id].spawnX = _.random(3, spawnRoom.width - 3);
				Game.rooms[spawnRoom.id].spawnY = _.random(3, spawnRoom.height - 3);
				Game.rooms[spawnRoom.id].name = "Spawn Room";

				let stairRoom;

				Game.rooms.forEach(room => {
					if (room.type !== "hub") return;

					if (!stairRoom) {
						stairRoom = room;
						return;
					}

					if (stairRoom.x + stairRoom.width < room.x + room.width) {
						stairRoom = room;
					}
				});

				Game.stairRoom = stairRoom.id;
				Game.rooms[stairRoom.id].subType = "stair";
				Game.rooms[stairRoom.id].name = "Stair Room";

				Game.rooms = _.map(Game.rooms, room => {
					if (room.type === "regular") {
						room.subType = _.sample(["camp", "empty", "mobs"]);

						switch(room.subType) {
							case "camp":
								room.name = _.sample(["Monster Camp", "Camp", "Small Camp"]);
								break;
							case "empty":
								room.name = _.sample(["Empty Room", "Abandoned Room"]);
								break;
							case "mobs":
								room.name = _.sample(["Monsters", "Sewer", "Mobs", "Dungeon", "Cells"]);
								break;
						}
					} else if (room.type === "hub" && !room.subType || (room.subType && room.subType !== "spawn" && room.subType !== "stair")) {
						room.subType = _.sample(["loot", "camp", "boss"]);

						switch(room.subType) {
							case "loot":
								room.name = _.sample(["Treasury", "Storage Room", "Armoury", "Abandoned Camp"]);
								break;
							case "camp":
								room.name = _.sample(["Monster Camp", "Camp", "Large Camp"]);
								break;
							case "boss":
								room.name = _.sample(["Boss", "Lair"]);
								break;
						}
					}

					return room;
				});

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
				let player = new Player(Game, user.name, token, user);
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
			subType: room.subType,
			name: room.name,
			touching: room.touching,
			touchingHubs: room.touchingHubs,
			touchingRegular: room.touchingRegulars,
			touchingHalls: room.touchingHalls
		};
	},

	roomIntersectsWithPoint(room, x, y) {
		return (room.x <= x &&
				room.x + room.width >= x &&
				room.y <= y &&
				room.y + room.height >= y);
	}
};

export default Game;