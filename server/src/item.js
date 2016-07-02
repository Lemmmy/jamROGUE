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
		}
	],
	"shooter": [
		{
			name: "Slingshot",
			description: "It's a{n} {name} - looks like it requires pebbles.",
			range: 8,
			projectiles: ["Pebble"]
		}
	],
	"projectile": [
		{
			name: "Pebble",
			description: "Might be useful for a slingshot or something.",
			minLevel: 0,
			damage: 1,
			stack: 30
		}
	],
	"consumable": [
		{
			name: "Apple",
			description: "An apple a day keeps the doctor away.",
			minLevel: 0,
			heal: 2,
			stack: 4,
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
		minLevel: 3
	},
	{
		name: "Superb",
		colour: CCColours.lime,
		minLevel: 4
	},
	{
		name: "Rare",
		colour: CCColours.yellow,
		minLevel: 8
	},
	{
		name: "Legendary",
		colour: CCColours.blue,
		minLevel: 12
	},
	{
		name: "Exalted",
		colour: CCColours.orange,
		minLevel: 15
	},
	{
		name: "Epic",
		colour: CCColours.red,
		minLevel: 20
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
		return {
			type: this.type,
			rarity: this.rarity ? this.rarity.name : null,
			name: this.item.name,
			fullName: this.rarity ? this.rarity.name + " " + this.item.name : this.item.name,
			maxStack: this.item.stack || 1,
			colour: this.rarity ? this.rarity.colour : CCColours.white,
			subType: this.item.subType,
			damage: this.item.damage,
			heal: this.item.heal,
			projectiles: this.item.projectiles,
			range: this.item.range,
			description: "&0" + this.item.description
							.replace("{name}", "&" + CCColours.colourToHex(this.rarity ? this.rarity.colour : CCColours.white) + (this.rarity ? this.rarity.name + " " : "") + this.item.name + "&0")
							.replace("{n}", this.rarity ? (/^[aeiou]/i.test(this.rarity.name) ? "n" : "") : "")
		};
	}

	static fromJSON(json) {
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