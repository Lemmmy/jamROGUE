import DB from "./db";
import CCColours from "./colours.js";

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

		setTimeout(this.ping.bind(this), 1000);

		if (user.dungeonID && user.dungeonID == this.Game.dungeonID) {
			this.visitedRooms = user.visitedRooms;
			this.room = user.room;
			this.x = user.x;
			this.y = user.y;
		} else {
			this.room = this.Game.spawnRoom;
			this.x = this.Game.rooms[this.Game.spawnRoom].x + this.Game.rooms[this.Game.spawnRoom].spawnX;
			this.y = this.Game.rooms[this.Game.spawnRoom].y + this.Game.rooms[this.Game.spawnRoom].spawnY;

			this.user.room = this.room;
			this.user.x = this.x;
			this.user.y = this.y;
			this.user.dungeonID = this.Game.dungeonID;

			this.user.save();

			this.addEvent("serverMessage", { text: "Welcome to a new dungeon.", colour: CCColours.lightBlue});
		}

		this.Game.broadcastToAllBut(this.name, "join", this.toJSON());
		this.addEvent("spawn", { player: this.toJSON(), players: _.map(this.Game.players, player => { return player.toJSON(); }) });
		this.addEvent("room", this.Game.roomToJSON(this.Game.rooms[this.room]));

		console.log(`Player ${this.name} connected`);
	}

	disconnect(reason) {
		this.deleted = true;

		console.log(`Player ${this.name} disconnected for reason ${reason}`);

		this.Game.players.splice(this.Game.players.indexOf(this), 1);

		this.Game.broadcast("quit", {
			name: this.name,
			reason: this.reason
		});
		this.Game.broadcast("online_users", this.Game.players.length);
	}

	ping() {
		if (this.deleted) return;

		if (!this.connected && new Date().getTime() - this.disconnectedTime.getTime() > 10000) {
			return this.disconnect("timeout");
		}

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
			console.log(`Req timeout from ${self.name}`);
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
			name: this.name
		};
	}

	move(x, y) {
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
			this.addEvent("room", gotRoom ? this.Game.roomToJSON(this.Game.rooms[this.room]) : {});
			this.notify();
		}

		this.user.x = this.x;
		this.user.y = this.y;
		this.user.room = this.room;

		this.user.save();
	}
}

export default Player;