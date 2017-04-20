import DB from "./db";
import Player from "./player";
import DungeonGenerator from "./dungeon";

import Item from "./item";
import EntityChest from "./entities/entity_chest";
import EntityDroppedItem from "./entities/entity_dropped_item";

import EntityRat from "./entities/entity_rat";
import EntityBat from "./entities/entity_bat";
import EntityGoblin from "./entities/entity_goblin";
import EntityDwarf from "./entities/entity_dwarf";
import EntityLizard from "./entities/entity_lizard";
import EntitySerpent from "./entities/entity_serpent";

import fs from "fs";
import hat from "hat";
import bcrypt from "bcrypt-nodejs";
import Promise from "bluebird";
import jsdom from "jsdom";

import _ from "lodash";

let Game = {
	lastPollID: 0,
	rooms: [],
	spawnRoom: 0,
	stairRoom: 0,
	dungeonID: hat(36),
	entities: [],
	tickTimer: 0,
	worldTime: 0,
	tickRate: 0.1,

	init() {
		return new Promise(resolve => {
			Game.players = [];

			DungeonGenerator.generate().then(result => {
				console.log("Yes");
				let rooms = result.rooms;
				Game.rooms = rooms;

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

				let mapSize = Game.distance(spawnRoom.x + (spawnRoom.width / 2), spawnRoom.y + (spawnRoom.height / 2),
											stairRoom.x + (stairRoom.width / 2), stairRoom.y + (stairRoom.height / 2));

				Game.rooms = _.map(Game.rooms, room => {
					room.sleeping = true;

					if (room.type === "regular") {
						room.subType = _.sample(["camp", "empty", "mobs"]);

						switch(room.subType) {
							case "camp":
								room.name = _.sample(["Monster Camp", "Camp", "Small Camp"]);
								Game.fillRoomWithMobs(room, 1, 2, _.sample([EntityGoblin]));
								break;
							case "empty":
								room.name = _.sample(["Empty Room", "Abandoned Room"]);

								if (Math.random() >= 0.65) {
									new EntityDroppedItem(Game, room.id, Math.floor(room.x + (room.width / 2)), Math.floor(room.y + (room.height / 2)), new Item(null, "misc", "Chest Key")).spawn();
								}

								var pebbleAmount = _.random (3, 12);
								var items = [
									["projectile", "Pebble"],
									["throwable", "Rock"]
								];

								for (var i = 0; i < pebbleAmount; i++) {

									var chosenItem = _.sample(items);
									var item = new Item(null, chosenItem[0], chosenItem[1]);

									new EntityDroppedItem(Game, room.id, _.random(room.x + 1, room.x + room.width - 1), _.random(room.y + 1, room.y + room.height - 1), item).spawn();
								}

								break;
							case "mobs":
								room.name = _.sample(["Monsters", "Sewer", "Mobs", "Dungeon", "Cells"]);
								Game.fillRoomWithChests(room, 1, 3, 0.2);
								Game.fillRoomWithMobs(room, 1, 4, _.sample([EntityRat, EntityBat]));
								break;
						}
					} else if (room.type === "hub" && !room.subType || (room.subType && room.subType !== "spawn" && room.subType !== "stair")) {
						let types = ["loot", "camp"];

						if (Game.distance(  spawnRoom.x + (spawnRoom.width / 2), spawnRoom.y + (spawnRoom.height / 2),
											room.x + (room.width / 2), room.y + (room.height / 2)) > mapSize / 4) {
							types.push("boss");
						}

						room.subType = _.sample(types);

						switch(room.subType) {
							case "loot":
								room.name = _.sample(["Treasury", "Storage Room", "Armoury", "Abandoned Camp"]);
								Game.fillRoomWithChests(room, 3, 10, 0.5);
								break;
							case "camp":
								room.name = _.sample(["Monster Camp", "Camp", "Large Camp"]);
								Game.fillRoomWithMobs(room, 2, 6, _.sample([EntityGoblin, EntityDwarf]));
								break;
							case "boss":
								room.name = _.sample(["Boss", "Lair"]);
								Game.fillRoomWithChests(room, 1, 3, 0.9);
								Game.fillRoomWithMobs(room, 2, 3, _.sample([EntityLizard, EntitySerpent]));
								break;
						}
					}

					return room;
				});

				console.log("About to generate SVG");

				Game.generateSVG(result.svgStuff).then(svg => {
					console.log("SVG ready");

					fs.writeFileSync("dungeon.svg", svg);

					console.log("Starting tick timer");
					Game.tickTimer = setInterval(Game.worldTick, Game.tickRate * 1000);

					resolve();
				});
			});
		});
	},

	generateSVG(svgStuff) {
		console.log("Generating SVG");

		return new Promise(resolve => {
			jsdom.env("<html></html>", [], (err, win) => {
				if (err) {
					return console.error(err);
				}

				console.log("Opened jsdom env");

				global.window = win;
				global.document = win.document;
				global.navigator = win.navigator;

				let raphael = require("raphael");
				raphael.setWindow(win);

				let paper = raphael(0, 0, svgStuff.imageWidth, svgStuff.imageHeight);

				Game.rooms.forEach(room => {
					let fill = "rgba(125, 125, 125, 0.4)";

					switch (room.type) {
						case "hub":
							switch (room.subType) {
								case "stair":
									fill = "rgba(255, 0, 0, 1)";
									break;
								case "spawn":
									fill = "rgba(0, 255, 0, 1)";
									break;
								case "loot":
									fill = "rgba(255, 215, 0, 0.6)";
									break;
								case "camp":
									fill = "rgba(106, 90, 205, 0.6)";
									break;
								case "boss":
									fill = "rgba(178, 34, 34, 0.6)";
									break;
							}
							break;
						case "hall":
							fill = "rgba(75, 75, 75, 1)";
							break;
					}

					let x = (Math.floor(svgStuff.imageWidth - (svgStuff.maxX + Math.abs(svgStuff.minX))) / 2) + room.x;
					let y = (Math.floor(svgStuff.imageHeight - (svgStuff.maxY + Math.abs(svgStuff.minY))) / 2) + room.y;

					let rect = paper.rect(Math.floor(Math.max(x, 0)), Math.floor(Math.max(y, 0)), Math.floor(room.width), Math.floor(room.height));
					rect.attr("fill", fill);
					rect.attr("stroke", "none");
				});

				let svg = win.document.documentElement.innerHTML.replace("<head></head><body>", "").replace("</body>", "");
				resolve(svg);
			});
		});
	},

	worldTick() {
		Game.worldTime += Game.tickRate;

		Game.players.forEach(p => {
			p.tick(Game.worldTime);
		});

		let aliveRooms = _.filter(Game.rooms, r => { return !r.sleeping; });

		if (aliveRooms) {
			let livingEntities = _.filter(Game.entities, e => { return _.find(aliveRooms, r => { return r.id === e.room; }); });

			if (livingEntities) {
				livingEntities.forEach(e => {
					e.tick(Game.worldTime);
				});
			}
		}
	},

	authPlayer(username, password, colour) {
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

				let token = hat();
				console.log(`Player ${user.name} connecting with ${token}`);

				let player = new Player(Game, user.name, token, user, colour);
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
	},

	distanceSq(ax, ay, bx, by) {
		return (ax - bx) * (ax - bx) + (ay - by) * (ay - by);
	},

	distance(ax, ay, bx, by) {
		return Math.sqrt(Game.distanceSq(ax, ay, bx, by));
	},

	playerDistanceSq(a, b) {
		return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y);
	},

	playerDistance(a, b) {
		return Math.sqrt(Game.playerDistanceSq(a, b));
	},

	playerDistancePointSq(a, bx, by) {
		return (a.x - bx) * (a.x - bx) + (a.y - by) * (a.y - by);
	},

	playerDistancePoint(a, bx, by) {
		return Math.sqrt(Game.playerDistancePointSq(a, bx, by));
	},

	playersNear(player, distance) {
		let d = distance * distance;

		return _.filter(_.without(Game.players, player), p => {
			return Game.playerDistanceSq(player, p) <= d;
		});
	},

	fillRoomWithChests(room, min, max, lockedRatio = 0.5) {
		let amt =  _.random(min, max);

		for (let i = 0; i < amt; i++) {
			let side = _.random(1, 4);

			let x = 0;
			let y = 0;

			switch (side) {
				case 1:
					x = room.x + 1;
					y = _.random(room.y + 1, room.y + room.height - 1);
					break;
				case 2:
					x = room.x + room.width - 1;
					y = _.random(room.y + 1, room.y + room.height - 1);
					break;
				case 3:
					x = _.random(room.x + 1, room.x + room.width - 1);
					y = room.y + 1;
					break;
				case 4:
					x = _.random(room.x + 1, room.x + room.width - 1);
					y = room.y + room.height - 1;
					break;
			}

			new EntityChest(Game, room.id, x, y, Math.random() <= lockedRatio).spawn();
		}
	},

	fillRoomWithMobs(room, min, max, cls) {
		let amt =  _.random(min, max);

		for (let i = 0; i < amt; i++) {
			new cls(Game, room.id, _.random(room.x + 1, room.x + room.width - 1), _.random(room.y + 1, room.y + room.height - 1)).spawn();
		}
	}
};

export default Game;
