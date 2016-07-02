import path from "path";
import Game from "../game";
import _ from "lodash";

export default app => {
	app.get("/map", (req, res) => {
		res.set("Content-Type", "text/html");
		res.send("<html style='width: 100%; height: 100%;'><head><title>jamROGUE map</title></head><body style='margin: 0; width: 100%; height: 100%;'><img src='/map.svg' /></body></html>");
	});

	app.get("/map.svg", (req, res) => {
		res.set("Content-Type", "image/svg+xml");
		res.sendFile(path.resolve(__dirname + "/../dungeon.svg"));
	});

	app.get("/map.json", (req, res) => {
		res.json({
			ok: true,
			rooms: _.map(Game.rooms, room => { return Game.roomToJSON(room); })
		});
	});

	app.post("/map.json", (req, res) => {
		if (!req.body.token) {
			return res.json({
				ok: false,
				error: "missing_token"
			});
		}

		let player = Game.getPlayerByToken(req.body.token);

		if (!player) {
			return res.json({
				ok: false,
				error: "invalid_token"
			});
		}

		res.json({
			ok: true,
			rooms: _.map(Game.rooms, r => {
				let room = Game.roomToJSON(r);
				room.visited = r.type == "hall" ||
					(r.type == "hub" && r.subType == "spawn") ||
					_.includes(player.visitedRooms, room.id);

				return room;
			})
		});
	});
};