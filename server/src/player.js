import DB from "./db";
import _ from "lodash";

class Player {
	constructor(game, name, token) {
		this.Game = game;

		this.name = name;
		this.token = token;

		this.buffer = [];

		this.connected = false;
		this.disconnectedTime = new Date();

		console.log(`Player ${this.name} connected`);

		setTimeout(this.ping.bind(this), 1000);
	}

	disconnect(reason) {
		console.log(`Player ${this.name} disconnected for reason ${reason}`);

		this.Game.players.splice(this.Game.players.indexOf(this), 1);
	}

	ping() {
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

		req.pause();

		this.connected = true;
	}
}

export default Player;