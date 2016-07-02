import Game from "../game";

let poopgex = new RegExp("[^a-zA-Z0-9 \\-\\[\\]\\\\\\\/\\^.,_+=(){}|!?<>:;@~`\u00B4\"\'*\u00F7#$\u00A3\u00A5\u00A2\u00A7\u00A9\u00AE\u00BC\u00BD\u00BE\u00BF\u00B1\u00B0\u00BA\u00B9\u00B2\u00B3\u00C0\u00C1\u00C2\u00C3\u00C4\u00C5\u00C6\u00C7\u00C8\u00C9\u00CA\u00CB\u00CC\u00CD\u00CE\u00CF\u00D0\u00D1\u00D2\u00D3\u00D4\u00D5\u00D6\u00D7\u00D8\u00D9\u00DA\u00DB\u00DC\u00DD\u00DE\u00DF\u00E0\u00E1\u00E2\u00E3\u00E4\u00E5\u00E5\u00E6\u00E7\u00E8\u00E9\u00EA\u00EB\u00EC\u00ED\u00EE\u00EF\u00F0\u00F1\u00F2\u00F3\u00F4\u00F5\u00F6\u00F8\u00F9\u00FA\u00FB\u00FC\u00FD\u00FE\u00FF]", "g");

export default app => {
	app.post("/game/chat", (req, res) => {
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

		if (!req.body.message) {
			return res.json({
				ok: false,
				error: "missing_message"
			});
		}

		let message = req.body.message.replace(poopgex, "");

		let nearby = Game.playersNear(player, 30);
		let ev = {
			from: player.name,
			message: message
		};

		nearby.forEach(p => {
			p.addEvent("chat", ev);
			p.notify();
		});

		player.addEvent("chat", ev);
		player.notify();

		res.json({
			ok: true,
			heard: nearby.length
		});
	});
};