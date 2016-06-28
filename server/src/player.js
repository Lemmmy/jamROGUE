import DB from "./db";
import _ from "lodash";

class Player {
	constructor(game, name, token, id) {
		this.Game = game;

		this.name = name;
		this.token = token;

		this.id = id;

		this.buffer = [];

		this.connected = false;
		this.disconnectedTime = new Date();

		this.deleted = false;

		this.room = 0;
		this.x = 0;
		this.y = 0;

		setTimeout(this.ping.bind(this), 1000);

		let self = this;

		DB.models.User.findById(this.id).then(user => {
			if (user.dungeonID && user.dungeonID == self.Game.dungeonID) {
				self.room = user.room;
				self.x = user.x;
				self.y = user.y;
			} else {
				self.room = self.Game.spawnRoom;
				self.x = self.Game.rooms[self.Game.spawnRoom].x + self.Game.rooms[self.Game.spawnRoom].spawnX;
				self.y = self.Game.rooms[self.Game.spawnRoom].y + self.Game.rooms[self.Game.spawnRoom].spawnY;
			}

			self.Game.broadcastToAllBut(self.name, "join", self.toJSON());
			self.addEvent("spawn", { player: self.toJSON(), players: _.map(self.Game.players, player => { return player.toJSON(); }) });
			self.addEvent("room", self.Game.roomToJSON(self.Game.rooms[self.room]));

			console.log(`Player ${self.name} connected`);
		});
	}

	disconnect(reason) {
		this.deleted = true;

		console.log(`Player ${this.name} disconnected for reason ${reason}`);

		this.Game.players.splice(this.Game.players.indexOf(this), 1);

		this.Game.broadcast("quit", {
			name: this.name
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

		this.Game.broadcastToAllBut(this.name, "move", {
			player: this.name,
			x: this.x,
			y: this.y,
			room: this.room
		});

		DB.models.User.findByIdAndUpdate(this.id, { x: this.x, y: this.y });
	}
}

export default Player;