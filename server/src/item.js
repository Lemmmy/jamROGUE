import CCColours from "./colours";

import _ from "lodash";

let types = ["melee", "throwable", "shooter", "projectile", "consumable"];

let items = {
	"melee": [
		{
			name: "Rusty Sword",
			description: "It's a{n} {name}, looks pretty old.",
			damage: 1,
			minLevel: 0
		},
		{
			name: "Club",
			description: "Some sort of {name} from somewhere.",
			damage: 1,
			minLevel: 0
		},
		{
			name: "Stick",
			description: "It's a{n} {name} but do we even have trees down here?",
			damage: 1,
			minLevel: 0
		},
		{
			name: "Branch",
			description: "It's a{n} {name} - is this really any better than a stick?",
			damage: 2,
			minLevel: 2
		},
		{
			name: "Knife",
			description: "Equally useful in the kitchen and the dungeon.",
			damage: 3,
			minLevel: 5
		},
		{
			name: "Sword",
			description: "It's a{n} {name}, looks sturdy.",
			damage: 3,
			minLevel: 5
		},
		{
			name: "Shortsword",
			description: "It's a{n} {name}, short and swift.",
			damage: 4,
			minLevel: 10
		},
		{
			name: "Longsword",
			description: "It's a{n} {name}.",
			damage: 5,
			minLevel: 13
		}
	],
	"throwable": [
		{
			name: "Rock",
			description: "Just a rock.",
			damage: 1,
			minLevel: 0,
			stack: 8,
			range: 6
		},
		{
			name: "Brick",
			description: "Just a brick.",
			damage: 1,
			minLevel: 0,
			stack: 10,
			range: 5
		},
		{
			name: "Can",
			description: "Just a can.",
			damage: 1,
			minLevel: 0,
			stack: 20,
			range: 10
		},
		{
			name: "Boulder",
			description: "How do you carry this?",
			damage: 5,
			minLevel: 10,
			stack: 3,
			range: 6
		}
	],
	"shooter": [
		{
			name: "Slingshot",
			description: "It's a{n} {name} - looks like it requires pebbles.",
			range: 8,
			projectiles: ["Pebble"]
		},
		{
			name: "Flimsy Bow",
			description: "It's a{n} {name}.",
			range: 12,
			projectiles: ["Arrow"],
			minLevel: 2
		},
		{
			name: "Bow",
			description: "It's a{n} {name}.",
			range: 15,
			projectiles: ["Arrow"],
			minLevel: 5
		},
		{
			name: "Strong Bow",
			description: "It's a{n} {name}.",
			range: 18,
			projectiles: ["Arrow"],
			minLevel: 10
		},
		{
			name: "Crossbow",
			description: "It's a{n} {name}.",
			range: 20,
			projectiles: ["Arrow"],
			minLevel: 12
		}
	],
	"projectile": [
		{
			name: "Pebble",
			description: "Might be useful for a slingshot or something.",
			minLevel: 0,
			damage: 1,
			stack: 30
		},
		{
			name: "Arrow",
			description: "Sharp and pointy.",
			minLevel: 2,
			damage: 2,
			stack: 30
		},
		{
			name: "Venom Arrow",
			description: "Sharp, pointy and venomous.",
			minLevel: 6,
			damage: 4,
			stack: 30
		}
	],
	"consumable": [
		{
			name: "Apple",
			description: "An apple a day keeps the doctor away.",
			minLevel: 0,
			heal: 2,
			stack: 6,
			subType: "healing"
		},
		{
			name: "Water Bottle",
			description: "It's healthier than soda.",
			minLevel: 0,
			heal: 1,
			verb: "drink",
			subType: "healing"
		},
		{
			name: "Poop",
			description: "You really don't want to eat this.",
			minLevel: 0,
			heal: 1,
			stack: 15,
			subType: "healing"
		},
		{
			name: "Pineapple",
			description: "A pineapple a day keeps the monsters away.",
			minLevel: 2,
			heal: 3,
			stack: 4,
			subType: "healing"
		},
		{
			name: "Health Potion",
			description: "Looks suspicious, but it says health on it!",
			minLevel: 4,
			heal: 5,
			subType: "healing"
		},
		{
			name: "Health Vial",
			description: "Looks suspicious, but it says health on it!",
			minLevel: 6,
			heal: 8,
			subType: "healing"
		},
		{
			name: "Cake",
			description: "Lucky find.",
			minLevel: 8,
			heal: 10,
			subType: "healing"
		}
	],
	"misc": [
		{
			name: "Chest Key",
			description: "A flimsy key that probably only works once.",
			minLevel: 0,
			subType: "chest_key"
		}
	]
};

let rarities = [
	{
		name: "Common",
		colour: CCColours.lightGrey,
		minLevel: 0
	},
	{
		name: "Regular",
		colour: CCColours.white,
		minLevel: 2,
		damageModifier: 1.2
	},
	{
		name: "Superb",
		colour: CCColours.lime,
		minLevel: 4,
		damageModifier: 1.5
	},
	{
		name: "Rare",
		colour: CCColours.yellow,
		minLevel: 6,
		damageModifier: 2
	},
	{
		name: "Legendary",
		colour: CCColours.blue,
		minLevel: 8,
		damageModifier: 3
	},
	{
		name: "Exalted",
		colour: CCColours.orange,
		minLevel: 10,
		damageModifier: 4
	},
	{
		name: "Epic",
		colour: CCColours.red,
		minLevel: 15,
		damageModifier: 5
	}
];

class Item {
	constructor(item, type, name, rarity, attributes) {
		if (item) {
			this.item = item;
			this.rarity = rarity;
			this.type = type;
		} else {
			this.item = _.find(items[type], i => { return i.name.toLowerCase() === name.toLowerCase(); });
			this.rarity = _.find(rarities, i => { return i.name.toLowerCase() === rarity; });
			this.type = type;
		}

		this.attributes = attributes;
	}

	serialize() {
		if (!this.item) {
			return {};
		}

		return {
			type: this.type,
			rarity: this.rarity ? this.rarity.name : null,
			name: this.item.name || "Invalid Item",
			fullName: this.rarity ? this.rarity.name + " " + (this.item.name || "Invalid Item") : (this.item.name || "Invalid Item"),
			maxStack: this.item.stack || 1,
			colour: this.rarity ? this.rarity.colour : CCColours.white,
			subType: this.item.subType,
			verb: this.item.verb,
			damage: this.item.damage,
			rarityDamageModifier: this.rarity ? this.rarity.damageModifier : null,
			heal: this.item.heal,
			projectiles: this.item.projectiles,
			range: this.item.range,
			description: "&0" + this.item.description
							.replace("{name}", "&" + CCColours.colourToHex(this.rarity ? this.rarity.colour : CCColours.white) + (this.rarity ? this.rarity.name + " " : "") + this.item.name + "&0")
							.replace("{n}", this.rarity ? (/^[aeiou]/i.test(this.rarity.name) ? "n" : "") : "")
		};
	}

	static fromJSON(json) {
		if (!json.name) {
			return null;
		}

		let item = _.find(items[json.type], i => { return i.name.toLowerCase() === json.name.toLowerCase(); });
		let rarity = json.rarity ? _.find(rarities, i => { return i.name.toLowerCase() === json.rarity.toLowerCase(); }) : null;

		return new Item(item, json.type, null, rarity);
	}

	static randomItem(type, level = 0) {
		let item = _.sample(_.filter(items[type], i => { return typeof i.minLevel !== "undefined" ? i.minLevel <= level : true; }));
		let rarity = type !== "consumable" && type !== "projectile" && type !== "throwable" ? _.sample(_.filter(rarities, r => { return r.minLevel <= level; })) : null;

		return new Item(item, type, null, rarity);
	}

	static randomRarity(type, level = 0) {
		let rarity = type !== "consumable" && type !== "projectile" && type !== "throwable" ? _.sample(_.filter(rarities, r => { return r.minLevel <= level; })) : null;

		return rarity;
	}

	static getTypes() {
		return types;
	}

	static getItems() {
		return items;
	}

	static getRarities() {
		return rarities;
	}
}

export default Item;