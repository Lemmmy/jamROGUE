import DB from "./db";
import _ from "lodash";

class Player {
	constructor(game, name, token) {
		this.Game = game;

		this.name = name;
		this.token = token;

		this.buffer = [];
		this.pending = [];

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
		buffer.push({
			type: type,
			data: data,
			time: new Date()
		});
	}

	nextEvent(time = 0) {
		let event;
		let minTime = new Date() - 60000;

		for (var i = 0; i < this.buffer.length; i++) {
			event = this.buffer[i];

			if (event.time < minTime) {
				this.buffer[i] = null;
				continue;
			}

			if (event.time > time) {
				break;
			}
		}

		this.buffer = _.compact(this.buffer);

		return event;
	}

	notify() {
		for (var i = 0; i < this.pending.length; i++) {
			let ctx = this.pending[i];

			if (!ctx.req) {
				this.pending[i] = null;
				continue;
			}

			let event = this.nextEvent(ctx.time);

			if (event) {
				ctx.req.resume();
				ctx.res.json({
					ok: true,
					event: event
				});

				self.connected = false;
				self.disconnectedTime = new Date();

				this.pending[i] = null;
			}
		}

		this.pending = _.compact(this.pending);
	}

	pause(time, req, res, pollID) {
		let ctx = {
			id: pollID,
			time: time,
			req: req,
			res: res
		};

		this.pending.push(ctx);

		let self = this;

		req.connection.setTimeout(60000);
		req.connection.on("timeout", () => {
			ctx.req = null;
			ctx.res = null;

			self.connected = false;
			self.disconnectedTime = new Date();
		});

		req.pause();

		this.connected = true;
	}
}

export default Player;