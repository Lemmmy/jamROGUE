import path from "path";
import Game from "../game";

export default app => {
	app.get("/map", (req, res) => {
		res.set("Content-Type", "image/png");
		res.sendFile(path.resolve(__dirname + "/../dungeon.png"));
	});

	app.get("/map.json", (req, res) => {
		let out = [];

		Game.rooms.forEach(room => {
			out[room.id] = {
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
		});

		res.json({
			ok: true,
			rooms: out
		});
	});
};