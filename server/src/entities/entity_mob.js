import Entity from "./entity";
import EntityDroppedItem from "./entity_dropped_item";
import Item from "../item";
import CCColours from "../colours";

import _ from "lodash";

class EntityMob extends Entity {
	constructor(game, room, x, y) {
		super(game, room, x, y);

		this.damage = 1;
		this.critChance = 0.1;
		this.critMultiplier = 1.5;

		this.damageTick = 10;

		this.health = 5;

		this.name = "Mob";
		this.n = "";

		this.drops = {};
	}

	tick(time) {
		let playersInRoom = _.filter(this.Game.players, p => { return p.alive && p.room === this.room; });

		if (!playersInRoom) {
			return;
		}

		let closestPlayer, d;

		playersInRoom.forEach(p => {
			let d1 = this.Game.playerDistancePointSq(p, this.x, this.y);

			if (!d || d1 < d) {
				d = d1;
				closestPlayer = p;
			}
		});

		if (!closestPlayer) {
			return;
		}

		if (Math.floor(time * 10) % this.damageTick == 0 && ((this.x === closestPlayer.x && this.y === closestPlayer.y) || Math.sqrt(d) <= 3)) {
			this.damagePlayer(closestPlayer);
		}

		if (Math.floor(time * 10) % 3 == 0) {
			this.moveTowards(closestPlayer);
		}
	}

	moveTowards(player) {
		let dx = 0;
		let dy = 0;

		if (player.x > this.x) {
			dx = 1;
		} else if (player.x < this.x) {
			dx = -1;
		}

		if (player.y > this.y) {
			dy = 1;
		} else if (player.y < this.y) {
			dy = -1;
		}

		let nx = this.x + dx;
		let ny = this.y + dy;

		let r = this.Game.rooms[this.room];

		let isInRoom = nx > r.x + 1 && nx < r.x + r.width - 1 && ny > r.y + 1 && ny < r.y + r.height - 1;
		let willCollideWithPlayer = nx === player.x && ny === player.y;
		let willCollideWithMob = _.find(this.Game.entities, m => { return m.room === this.room && nx === m.x && ny === m.y; });

		if ((dx !== 0 || dy !== 0) && isInRoom && !willCollideWithPlayer && !willCollideWithMob) {
			this.move(nx, ny);
		}
	}

	damagePlayer(player) {
		player.addEvent("server_message", {
			text: `A${this.n} ${this.name} hits you!`,
			colour: CCColours.red
		});

		player.damage(this.damage * (Math.random() <= this.critChance ? this.critMultiplier : 1));
	}

	getType() {
		return "BaseMob";
	}

	getMobType() {
		return "BaseMob";
	}

	serialize() {
		return _.merge(super.serialize(), {
			mob_type: this.getMobType(),
			health: this.health,
			damage: this.damage,
			crit_chance: this.critChance,
			crit_multiplier: this.critMultiplier,
			name: this.name,
			n: this.n
		});
	}

	die(killer) {
		let items = [];

		_.forOwn(this.drops, (value, key) => {
			if (_.includes(Item.getTypes(), key)) {
				if (Math.random() <= value.chance) {
					let count = _.random(value.min || 1, value.max || 1);

					for (let i = 0; i < count; i++) {
						items.push(Item.randomItem(key, killer.level));
					}
				}
			}

			_.forOwn(Item.getItems(), type => {
				let poop = _.find(type, i => {
					return i.name.toLowerCase() === key.toLowerCase();
				});

				if (poop) {
					let count = _.random(value.min || 1, value.max || 1);

					for (let i = 0; i < count; i++) {
						items.push(new Item(poop, poop.type, null, value.rarity ? Item.randomRarity(poop.type, killer.level) : null));
					}
				}
			});

		});

		items.forEach(i => {
			new EntityDroppedItem(this.Game, this.room, this.x, this.y, i).spawn();
		});

		this.remove();
	}

	takeDamage(damage, damager) {
		damager.damageCooldownTicks = 8;

		this.health -= Math.max(Math.ceil(damage), 0);

		if (this.health <= 0) {
			this.die(damager);

			return true;
		} else {
			return false;
		}
	}

	inspect() {
		return `It's a${this.n} &e${this.name}&0.`;
	}

	interact(player) { // please kill me
		if (player.damageCooldownTicks < 0) {
			player.addEvent("server_message", {
				text: `You're still preparing your next attack.`,
				colour: CCColours.red
			});

			return player.notify();
		}

		if (!player.inventory || player.inventory.length <= 0) {
			player.addEvent("server_message", {
				text: `You swing at the ${this.name} but nothing happens.`,
				colour: CCColours.red
			});

			return player.notify();
		}

		let equippedItem = _.find(player.inventory, "equipped");
		let itemName = (equippedItem.count && equippedItem.count > 1 ?
						("a" + (equippedItem.item.rarity ? (/^[aeiou]/i.test(equippedItem.item.rarity) ? "n" : "") :
						(/^[aeiou]/i.test(equippedItem.item.name) ? "n" : ""))) : "the") +
						" &" + CCColours.colourToHex(equippedItem.item.rarity ? equippedItem.item.colour : CCColours.white) +
						(equippedItem.item.rarity ? equippedItem.item.rarity + " " : "") + equippedItem.item.name;

		if (!equippedItem) {
			player.addEvent("server_message", {
				text: `You swing your hands at the ${this.name} but nothing happens.`,
				colour: CCColours.red
			});

			return player.notify();
		}

		let distance = this.Game.playerDistancePoint(player, this.x, this.y);

		switch (equippedItem.item.type) {
			case "melee":
				if (distance > (equippedItem.range || 3)) {
					player.addEvent("server_message", {
						text: `&eYou swing ${itemName}&e at the ${this.name} but you can't reach.`,
						fancy: true
					});

					return player.notify();
				}

				player.addEvent("server_message", {
					text: `&eYou swing ${itemName}&e at the ${this.name}.`,
					fancy: true
				});

				if (this.takeDamage(equippedItem.item.damage, player)) {
					player.addEvent("server_message", {
						text: `You killed the ${this.name}.`,
						colour: CCColours.lime
					});
				}

				break;
			case "shooter":
				var projectile = _.find(player.inventory, i => {
					return i.item.type === "projectile" && _.includes(equippedItem.item.projectiles, i.item.name);
				});

				if (!projectile) {
					player.addEvent("server_message", {
						text: `&0You don't have any ammunition for the ${itemName}&0.`,
						fancy: true
					});

					return player.notify();
				}

				var projectileName = (projectile.count && projectile.count > 1 ?
						("a" + (projectile.item.rarity ? (/^[aeiou]/i.test(projectile.item.rarity) ? "n" : "") :
						(/^[aeiou]/i.test(projectile.item.name) ? "n" : ""))) : "the") +
						" &" + CCColours.colourToHex(projectile.item.rarity ? projectile.item.colour : CCColours.white) +
						(projectile.item.rarity ? projectile.item.rarity + " " : "") + projectile.item.name;

				if (projectile.count <= 1) {
					player.inventory.splice(player.inventory.indexOf(projectile), 1);
				} else {
					projectile.count--;
				}

				player.updateInventory();

				if (distance > (equippedItem.item.range || 3)) {
					player.addEvent("server_message", {
						text: `&eYou shoot ${projectileName}&e at the ${this.name} but it doesn't reach.`,
						fancy: true
					});

					return player.notify();
				}

				player.addEvent("server_message", {
					text: `&3You shoot ${projectileName}&3 at the ${this.name}.`,
					fancy: true
				});

				if (this.takeDamage(projectile.item.damage, player)) {
					player.addEvent("server_message", {
						text: `You killed the ${this.name}.`,
						colour: CCColours.lime
					});
				}

				break;
			case "throwable":
				if (equippedItem.count <= 1) {
					player.inventory.splice(player.inventory.indexOf(equippedItem), 1);
				} else {
					equippedItem.count--;
				}

				player.updateInventory();

				if (distance > (equippedItem.item.range || 3)) {
					player.addEvent("server_message", {
						text: `&eYou throw ${itemName}&e at the ${this.name} but it doesn't reach.`,
						fancy: true
					});

					return player.notify();
				}

				player.addEvent("server_message", {
					text: `&3You throw ${itemName}&3 at the ${this.name}.`,
					fancy: true
				});

				if (this.takeDamage(equippedItem.item.damage, player)) {
					player.addEvent("server_message", {
						text: `You killed the ${this.name}.`,
						colour: CCColours.lime
					});
				}

				break;
		}
	}
}

export default EntityMob;