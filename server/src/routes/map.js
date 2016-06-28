import path from "path";
import Game from "../game";
import _ from "lodash";

export default app => {
	app.get("/map", (req, res) => {
		res.set("Content-Type", "image/png");
		res.sendFile(path.resolve(__dirname + "/../dungeon.png"));
	});

	app.get("/map.json", (req, res) => {
		res.json({
			ok: true,
			rooms: _.map(Game.rooms, room => { return Game.roomToJSON(room); })
		});
	});
};