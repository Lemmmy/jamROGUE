import fs from "fs";
import gm from "gm";
import util from "util";
import now from "performance-now";
import _ from "lodash";

let DungeonGenerator = {};

let g = gm(768, 768, "white");

let rooms = [];

let tileSize = 4;
let roomCount = 150;

let minRoomWidth = 8;
let maxRoomWidth = 28;

let minRoomHeight = 8;
let maxRoomHeight = 24;

let hubRatio = 1.3;

let padding = 1;

let ellipseWidth = 150;
let ellipseHeight = 30;

function roundm(n, m) {
	return Math.floor(((n + m - 1) / m)) * m;
}

function getRandomPointInEllipse(width, height) {
	let t = 2 * Math.PI * Math.random();
	let u = Math.random() + Math.random();
	let r;

	if (u > 1) {
		r = 2 - u;
	} else {
		r = u;
	}

	return [roundm(width * r * Math.cos(t) / 2, tileSize),
		roundm(height * r * Math.sin(t) / 2, tileSize)];
}

class Room {
	constructor(id, x, y, width, height) {
		this.id = id;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;

		if (this.height < 0) {
			this.y += this.height;
			this.height = Math.abs(this.height);
		}

		this.type = "regular";
	}

	getLeft() {
		return this.x;
	}

	getRight() {
		return this.x + this.width;
	}

	getTop() {
		return this.y;
	}

	getBottom() {
		return this.y + this.height;
	}

	getArea() {
		return this.width * this.height;
	}

	getCenterX() {
		return this.x + (this.width / 2);
	}

	getCenterY() {
		return this.y + (this.height / 2);
	}

	touches(b, padding = 0) {
		let a = this;

		return (a.getLeft() <= b.getRight() - padding &&
				a.getRight() >= b.getLeft() - padding &&
				a.getTop() <= b.getBottom() - padding &&
				a.getBottom() >= b.getTop() - padding);
	}

	shift(x, y) {
		if (x == 0 && y == 0) return;

		this.x = Math.round(this.x + x);
		this.y = Math.round(this.y + y);
	}

	expand(by) {
		this.x -= by;
		this.y -= by;
		this.width += by * 2;
		this.height += by * 2;
	}
}

function poop(a, b) {
	return (a.x <= b.x + b.width &&
			a.x + a.width >= b.x &&
			a.y <= b.y + b.height &&
			a.y + a.height >= b.y);
}

DungeonGenerator.generate = () => {
	return new Promise((resolve, reject) => {
		var start = now();

		for (let i = 0; i < roomCount; i++) {
			let point = getRandomPointInEllipse(ellipseWidth, ellipseHeight);

			let x = point[0];
			let y = point[1];
			let width = _.random(minRoomWidth, maxRoomWidth);
			let height = _.random(minRoomHeight, maxRoomHeight);

			rooms[i] = new Room(i, x, y, width, height);
		}

		let widthTotal = 0;
		let heightTotal = 0;

		let widthMean = 0;
		let heightMean = 0;

		rooms.forEach(room => {
			widthTotal += room.width;
			heightTotal += room.height;
		});

		widthMean = widthTotal / roomCount;
		heightMean = heightTotal / roomCount;

		let iteration = 0;

		{
			let a, b;
			let dx, dxa, dxb, dy, dya, dyb;

			let touching;

			do {
				touching = false;

				if (++iteration >= roomCount * 3) {
					break;
				}

				for (let i = 0; i < rooms.length; i++) {
					a = rooms[i];

					for (let j = i + 1; j < rooms.length; j++) {
						b = rooms[j];

						if (a.touches(b, padding)) {
							touching = true;

							dx = Math.min(a.getRight() - b.getLeft() + padding, a.getLeft() - b.getRight() - padding);
							dy = Math.min(a.getBottom() - b.getTop() + padding, a.getTop() - b.getBottom() - padding);

							if (Math.abs(dx) < Math.abs(dy)) {
								dy = 0;
							} else {
								dx = 0;
							}

							dxa = -dx / 2;
							dxb = dx + dxa;

							dya = -dy / 2;
							dyb = dy + dya;

							a.shift(dxa, dya);
							b.shift(dxb, dyb);
						}
					}
				}
			} while (touching);
		}

		let hubCount = 0;

		rooms.forEach(room => {
			if (room.width > widthMean * hubRatio && room.height > heightMean * hubRatio) {
				room.type = "hub";
				hubCount++;
			}
		});

		{
			let a, b, c;
			let abDist, acDist, bcDist;
			let skip;

			let bigRooms = rooms.filter(room => {
				return room.type === "hub"
			});

			for (let i = 0; i < bigRooms.length; i++) {
				a = bigRooms[i];

				for (let j = i + 1; j < bigRooms.length; j++) {
					skip = false;
					b = bigRooms[j];

					abDist = Math.pow(a.getCenterX() - b.getCenterX(), 2) + Math.pow(a.getCenterY() - b.getCenterY(), 2);

					for (let k = 0; k < bigRooms.length; k++) {
						if (k === i || k === j) continue;

						c = bigRooms[k];

						acDist = Math.pow(a.getCenterX() - c.getCenterX(), 2) + Math.pow(a.getCenterY() - c.getCenterY(), 2);
						bcDist = Math.pow(b.getCenterX() - c.getCenterX(), 2) + Math.pow(b.getCenterY() - c.getCenterY(), 2);

						if (acDist < abDist && bcDist < abDist) {
							skip = true;
						}

						if (skip) {
							break;
						}
					}

					if (!skip) {
						if (!rooms[a.id].touching)
							rooms[a.id].touching = [];

						rooms[a.id].touching.push(b.id);
					}
				}
			}
		}

		{
			let dx, dy, x, y;
			let a, b;

			rooms.filter(room => {
				return room.type === "hub"
			}).forEach(outer => {
				if (!outer.touching) return;

				outer.touching.forEach(rid => {
					let inner = rooms[rid];

					if (outer.getCenterX() < inner.getCenterX()) {
						a = outer;
						b = inner;
					} else {
						a = inner;
						b = outer;
					}

					x = Math.floor(a.getCenterX());
					y = Math.floor(a.getCenterY());
					dx = Math.floor(b.getCenterX() - x);
					dy = Math.floor(b.getCenterY() - y);

					if (Math.random() >= 0.5) {
						let room1 = new Room(rooms.length, x, y, dx + 1, 1);
						room1.type = "hall";
						rooms.push(room1)

						let room2 = new Room(rooms.length, x + dx, y, 1, dy);
						room2.type = "hall";
						rooms.push(room2);
					} else {
						let room1 = new Room(rooms.length, x, y + dy, dx + 1, 1);
						room1.type = "hall";
						rooms.push(room1)

						let room2 = new Room(rooms.length, x, y, 1, dy);
						room2.type = "hall";
						rooms.push(room2);
					}
				});
			});
		}

		rooms.filter(a => {
			return a.type === "hall"
		}).forEach(hall => {
			hall.expand(1);
		});

		rooms.forEach(room => {
			let touched = false;

			rooms.filter(a => {
				return a.type === "hall"
			}).forEach(hall => {
				if (room.touches(hall)) {
					touched = true;
				}
			});

			room.touched = touched;
		});

		let minX = 0;
		let maxX = 0;
		let minY = 0;
		let maxY = 0;

		rooms.forEach(room => {
			if (room.getLeft() < minX) {
				minX = room.getLeft();
			}

			if (room.getRight() > maxX) {
				maxX = room.getRight();
			}

			if (room.getTop() < minY) {
				minY = room.getTop();
			}

			if (room.getBottom() > maxY) {
				maxY = room.getBottom();
			}
		});

		rooms.forEach(room => {
			room.shift(-minX, -minY);
		});

		var end = now();

		let outRooms = [];

		rooms.forEach(room => {
			if (!room.touched) return;

			room.id = outRooms.length;
			outRooms.push({
				id: room.id,
				x: room.x,
				y: room.y,
				width: room.width,
				height: room.height,
				type: room.type,
				name: "Cool Room"
			});
		});

		outRooms = _.sortBy(outRooms, o => { return o.type === "hall" ? 0 : o.type === "regular" ? 1 : 2 });
		outRooms = _.map(outRooms, (room, id) => { room.id = id; return room; });

		outRooms.forEach(a => {
			a.touching = [];
			a.touchingHubs = [];
			a.touchingRegulars = [];
			a.touchingHalls = [];

			outRooms.forEach(b => {
				if (a.id === b.id) {
					return;
				}

				if (poop(a, b)) {
					a.touching.push(b.id);

					if (b.type === "hub") {
						a.touchingHubs.push(b.id);
					} else if (b.type === "regular") {
						a.touchingRegulars.push(b.id);
					} else if (b.type === "hall") {
						a.touchingHalls.push(b.id);
					}
				}
			});
		});

		outRooms.forEach(room => {
			let alpha = room.type === "hub" ? "88" : room.type === "hall" ? "33" : "aa";
			g.fill((room.type === "hub" ? "#ff0000" : room.type === "hall" ? "#00ff00" : "#0000ff") + alpha);

			let x = (Math.floor(512 - (maxX + Math.abs(minX))) / 2) + room.x;
			let y = (Math.floor(512 - (maxY + Math.abs(minY))) / 2) + room.y;

			g.drawRectangle(Math.max(x, 0), Math.max(y, 0), Math.min(x + room.width), Math.min(y + room.height));
		});

		g.stroke("transparent", 0).fill("white").font("Lato.ttf").fontSize(8);

		outRooms.forEach(room => {
			let x = (512 - (maxX + Math.abs(minX))) / 2 + room.x;
			let y = (512 - (maxY + Math.abs(minY))) / 2 + room.y;

			g.drawText(x + 2, y + 8, room.id);
		});

		/*g.fill("transparent").stroke("#00000088", 1);

		rooms.filter(room => {
			return room.type === "hub"
		}).forEach(room => {
			if (room.touching) {
				let x0 = (512 - (maxX + Math.abs(minX))) / 2 + room.getCenterX();
				let y0 = (512 - (maxY + Math.abs(minY))) / 2 + room.getCenterY();

				room.touching.forEach(rid => {
					let room2 = rooms.filter(a => {
						return a.id === rid
					})[0];

					let x1 = (512 - (maxX + Math.abs(minX))) / 2 + room2.getCenterX();
					let y1 = (512 - (maxY + Math.abs(minY))) / 2 + room2.getCenterY();

					g.drawLine(Math.max(x0, 0), Math.max(y0, 0), Math.min(x1, 512), Math.min(y1, 512));
				});
			}
		});

		g.stroke("red", 2).drawLine(256, 256 - 8, 256, 256 + 8).drawLine(256 - 8, 256, 256 + 8, 256)

		g.fill("black").stroke("transparent").fontSize(12).drawText(4, 14,
			`Rooms: ${roomCount}\n` +
			`Width mean: ${widthMean}\n` +
			`Height mean: ${heightMean}\n` +
			`Min X: ${minX}\n` +
			`Min Y: ${minY}\n` +
			`Max X: ${maxX}\n` +
			`Max Y: ${maxY}\n` +
			`Shift iterations: ${iteration}\n` +
			`Time taken: ${(end - start).toFixed(3)} ms`);*/

		g.write("dungeon.png", err => {
			if (err)
				console.error(err);
		});

		resolve(outRooms);
	});
}

export default DungeonGenerator;