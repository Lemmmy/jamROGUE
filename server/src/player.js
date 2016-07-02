import DB from "./db";
import Item from "./item";
import CCColours from "./colours";

import util from "util";
import _ from "lodash";

class Player {
	constructor(game, name, token, user) {
		this.Game = game;

		this.name = name;
		this.token = token;

		this.user = user;

		this.buffer = [];

		this.connected = false;
		this.disconnectedTime = new Date();

		this.deleted = false;

		this.room = 0;
		this.x = 0;
		this.y = 0;
		this.visitedRooms = [];

		this.inventory = [];

		this.alive = typeof user.alive !== "undefined" ? user.alive : true;
		this.health = user.health || 5;
		this.level = user.level || 1;
		this.xp = user.xp || 0;

		this.lastMove = 0;

		this.damageCooldownTicks = 0;

		setTimeout(this.ping.bind(this), 1000);

		if (user.dungeonID && user.dungeonID == this.Game.dungeonID) {
			this.visitedRooms = user.visitedRooms;
			this.room = user.room;
			this.x = user.x;
			this.y = user.y;

			this.alive = typeof user.alive !== "undefined" ? user.alive : true;
			this.health = user.health;
			this.level = user.level;
			this.xp = user.xp || 0;

			this.inventory = _.map(user.inventory, i => {
				return {
					count: i.count,
					equipped: i.equipped,
					item: Item.fromJSON(i.item)
				};
			});
		} else {
			this.room = this.Game.spawnRoom;
			this.x = this.Game.rooms[this.Game.spawnRoom].x + this.Game.rooms[this.Game.spawnRoom].spawnX;
			this.y = this.Game.rooms[this.Game.spawnRoom].y + this.Game.rooms[this.Game.spawnRoom].spawnY;

			if (user.inventory && user.inventory.length > 0) {
				this.inventory = _.map(user.inventory, i => {
					return {
						count: i.count,
						equipped: i.equipped,
						item: Item.fromJSON(i.item)
					};
				});

				this.alive = typeof user.alive !== "undefined" ? user.alive : true;
				this.health = user.health;
				this.level = user.level;
				this.xp = user.xp || 0;
			}

			if (this.inventory.length <= 0) {
				this.inventory.push({
					count: 1,
					equipped: true,
					item: Item.randomItem("melee", this.level)
				});

				this.inventory.push({
					count: 2,
					equipped: false,
					item: Item.randomItem("consumable", this.level)
				});
			}

			this.user.alive = this.alive;
			this.user.room = this.room;
			this.user.x = this.x;
			this.user.y = this.y;
			this.user.dungeonID = this.Game.dungeonID;

			this.saveInventory();

			this.addEvent("server_message", { text: "Welcome to a new dungeon.", colour: CCColours.lightBlue});
		}

		this.Game.broadcastToAllBut(this.name, "join", this.toJSON());

		this.spawn();
	}

	spawn() {
		this.addEvent("spawn", { player: this.toJSON(), players: _.map(this.Game.players, player => { return player.toJSON(); }) });

		if (this.room >= 0) {
			if (this.room && this.Game.rooms[this.room] && this.Game.rooms[this.room].sleeping) {
				this.Game.rooms[this.room].sleeping = false;
			}

			let room = this.Game.roomToJSON(this.Game.rooms[this.room]);

			room.visited = true;
			room.entities = _.map(_.filter(this.Game.entities, { room: this.room }), e => { return e.serialize(); });

			this.addEvent("room", room);
		}

		if (this.health <= 0) {
			this.die();
		}

		if (this.alive) {
			this.user.alive = true;

			this.user.save();
		}
	}

	disconnect(reason) {
		this.deleted = true;

		this.user.save();

		console.log(`Player ${this.name} disconnected for reason ${reason}`);

		this.Game.players.splice(this.Game.players.indexOf(this), 1);

		this.Game.broadcast("quit", {
			name: this.name,
			reason: this.reason
		});
		this.Game.broadcast("online_users", this.Game.players.length);

		let hasPlayers = false;

		this.Game.players.forEach(p => {
			if (p.name.toLowerCase() === this.name.toLowerCase()) {
				return;
			}

			if (p.room == this.room) {
				hasPlayers = true;
			}
		});

		if (!hasPlayers) {
			if (this.room && this.Game.rooms[this.room]) {
				this.Game.rooms[this.room].sleeping = true;
			}
		}
	}

	ping() {
		if (this.deleted) return;

		if (!this.connected && new Date().getTime() - this.disconnectedTime.getTime() > 5000) {
			return this.disconnect("timeout");
		}

		this.user.save();

		setTimeout(this.ping.bind(this), 1000);
	}

	addEvent(type, data) {
		this.buffer.push({
			type: type,
			data: data,
			time: new Date()
		});
	}

	getEvents() {
		let buffer = this.buffer;
		this.buffer = [];
		return buffer;
	}

	notify() {
		if (this.req && this.res) {
			this.req.resume();
			this.res.json({
				ok: true,
				events: this.getEvents()
			});
			this.res.end();

			this.req.connection.removeAllListeners();

			this.req = null;
			this.res = null;

			this.connected = false;
			this.disconnectedTime = new Date();
		}
	}

	pause(req, res) {
		this.req = req;
		this.res = res;

		let self = this;

		req.connection.setTimeout(20000);
		req.connection.on("timeout", () => {
			self.req = null;
			self.res = null;

			self.connected = false;
			self.disconnectedTime = new Date();
		});

		setTimeout((() => {
			if (this.req != req) return;

			this.addEvent("pong", new Date().getTime());
			this.notify();
		}).bind(this), 15000);

		req.pause();

		this.connected = true;
	}

	toJSON() {
		return {
			roomID: this.room,
			x: this.x,
			y: this.y,
			name: this.name,
			health: this.health,
			level: this.level,
			xp: this.xp,
			inventory: _.map(this.inventory, i => {
				if (i.item instanceof Item) {
					i.item = i.item.serialize();
				}

				return i;
			}),
			alive: this.alive
		};
	}

	move(x, y) {
		if (!this.alive) return;

		this.x = x;
		this.y = y;

		let self = this;
		let gotRoom = false;
		let oldRoom = this.room;

		this.Game.rooms.forEach(room => {
			if (room.type === "hall" || gotRoom) return;

			if (self.Game.roomIntersectsWithPoint(room, self.x, self.y)) {
				gotRoom = true;
				self.room = room.id;
			}
		});

		this.Game.broadcastToAllBut(this.name, "move", {
			player: this.name,
			x: this.x,
			y: this.y,
			room: this.room
		});

		if (!gotRoom) {
			this.room = -1;
		}

		if (oldRoom !== this.room) {
			let room;

			let hasPlayers = false;

			this.Game.players.forEach(p => {
				if (p.name.toLowerCase() === this.name.toLowerCase()) {
					return;
				}

				if (p.room == oldRoom) {
					hasPlayers = true;
				}
			});

			if (!hasPlayers) {
				if (oldRoom && this.Game.rooms[oldRoom]) {
					this.Game.rooms[oldRoom].sleeping = true;
				}
			}

			if (gotRoom) {
				if (this.room && this.Game.rooms[this.room] && this.Game.rooms[this.room].sleeping) {
					this.Game.rooms[this.room].sleeping = false;
				}

				room = this.Game.roomToJSON(this.Game.rooms[this.room]);

				room.visited = true;
				room.entities = _.map(_.filter(this.Game.entities, { room: this.room }), e => {
					return e.serialize();
				});
			}

			this.addEvent("room", gotRoom ? room : {});
			this.notify();

			this.visitedRooms.push(this.room);
		}

		this.user.x = this.x;
		this.user.y = this.y;

		if (oldRoom !== this.room) {
			this.user.room = this.room;
			this.user.visitedRooms = this.visitedRooms;
		}
	}

	addToInventory(item, inventoryOffset = 0) {
		if (!this.alive) return;

		let maxStack = (item instanceof Item ? item.item.stack : item.maxStack) || 1;

		if (maxStack <= 1) {
			if (this.inventory.length < 9 + inventoryOffset) {
				this.inventory.push({
					count: 1,
					item: item
				});

				return true;
			}
		} else if (maxStack > 1) {
			let existingStack = _.find(this.inventory, i => {
				return i.item.name.toLowerCase() === (item.name ? item.name.toLowerCase() : item.item.name.toLowerCase()) && i.count < maxStack;
			});

			if (!existingStack) {
				if (this.inventory.length < 9 + inventoryOffset) {
					this.inventory.push({
						count: 1,
						item: item
					});

					return true;
				}
			} else {
				this.inventory[this.inventory.indexOf(existingStack)].count++;

				return true;
			}
		}

		return false;
	}

	updateInventory() {
		if (!this.alive) return;

		this.addEvent("inventory", _.map(this.inventory, i => {
			if (i.item instanceof Item) {
				i.item = i.item.serialize();
			}

			return i;
		}));
	}

	saveInventory() {
		if (!this.alive) return;

		this.user.inventory = _.map(this.inventory, i => {
			if (i.item instanceof Item) {
				i.item = i.item.serialize();
			}

			return i;
		});
	}

	tick(time) {

	}

	die() {
		this.alive = false;

		let hasPlayers = false;

		this.Game.players.forEach(p => {
			if (p.name.toLowerCase() === this.name.toLowerCase()) {
				return;
			}

			if (p.room == this.room) {
				hasPlayers = true;
			}
		});

		if (!hasPlayers) {
			if (this.room && this.Game.rooms[this.room]) {
				this.Game.rooms[this.room].sleeping = true;
			}
		}

		this.Game.broadcastToAllBut(this.name, "player_died", { name: this.name });

		this.user.alive = false;
		this.user.save();

		return this.addEvent("dead");
	}

	damage(damage) {
		if (!this.alive) return;

		this.health -= Math.max(Math.ceil(damage), 0);
		this.user.health = this.health;

		this.user.save();

		if (this.health <= 0) {
			this.die();
		}

		this.addEvent("damage", {
			health: this.health
		});

		this.notify();
	}

	addXP(xp) {
		let oldLevel = this.level;
		let maxXP = 10 * Math.pow(1.25, this.level);

		if (this.xp + xp > maxXP) {
			let extraXP = xp - (maxXP - this.xp);

			this.xp = extraXP;
			this.level++;
		} else {
			this.xp += xp;
		}

		this.addEvent("xp", {
			xp: this.xp,
			level: this.level,
			oldLevel: oldLevel
		});
	}
}

export default Player;