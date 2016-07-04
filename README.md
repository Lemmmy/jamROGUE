<p align="center">
	<img alt="jamROGUE - A Multiplayer Roguelike for ComputerCraft" src="http://jamrogue.lemmmy.pw/banner.png" />
</p>

jamROGUE is a fully realtime multiplayer roguelike for ComputerCraft, originally made for CCJam 2016. It features a large dungeon which players can explore solo or together in a shared world, fighting mobs and collecting items. jamROGUE is currently in **Alpha**.

<h3 align="center">
	<a href="https://github.com/Lemmmy/CCJam-2016/issues?q=is%3Aopen+is%3Aissue+label%3Avote">Votes</a> - <a href="https://github.com/Lemmmy/CCJam-2016/issues?q=is%3Aopen+is%3Aissue+label%3A%22open+to+suggestions%22">Suggestions Wanted</a> -  <a href="https://github.com/Lemmmy/CCJam-2016/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22">Help Wanted</a>
</h3>

----------

# Table of Contents

- [Client](#)
	- [Recommended Environment](#)
	- [Controls](#)
	- [Rooms](#)
	- [Mobs](#)
	- [Item Rarities](#)
	- [Items](#)
- [Contributing](#)
- [Server](#)
	- [Installation (Linux)](#)
- [License](#)

----------


# Client
You can download the client installer by running `pastebin run t9aev7fA`.

## Recommended Environment
jamROGUE is developed and tested in [CCEmuRedux](http://www.computercraft.info/forums2/index.php?/topic/18789-ccemuredux-computercraft-emulator-redux/). It has been claimed to run perfectly in-game too, though ComputerCraft 1.76 or above is required due to the use of the new font. CCLite does not work.

**Warning:** the game may not run on some multiplayer servers. Do not bother reporting this to me or the server admin, just stop playing it on multiplayer servers. If it works, great!

## Controls
<p align="center">
	<img src="http://jamrogue.lemmmy.pw/controls.png" />
</p>

- **WASD / Arrow Keys** - Move the player
- **Left Click** - Inspect an item, player or mob, controls GUIs
- **Right Click** - Interact with an item, player or mob, also quick-equips items in the inventory

## Rooms
### ![Green Room](http://jamrogue.lemmmy.pw/green.png) Spawn Room
This is the room every player spawns in when the dungeon is created, and returns to after death. Mobs never spawn in this room - it is a safe room.

### ![Grey Room](http://jamrogue.lemmmy.pw/grey.png) Hallway
These nameless rooms simply serve as a connection between rooms. Mobs never spawn in hallways.

### ![Grey Room](http://jamrogue.lemmmy.pw/grey.png) Small Camps
Also referred to as Monster Camps or just Camps, these rooms often contain a few monsters - usually one or two Goblins.

### ![Grey Room](http://jamrogue.lemmmy.pw/grey.png) Empty Rooms
Also referred to as Abandoned Rooms, these rooms are usually empty and filled with Pebbles and Rocks. They additionally have a 65% chance of containing Chest Keys.

### ![Grey Room](http://jamrogue.lemmmy.pw/grey.png) Monster Rooms
Seen as Monsters, Sewers, Mobs, Dungeons or Cells - these small rooms usually contain one to four bats or rats as well as one to three chests, with a 20% chance of any of those chests being locked chests.

### ![Red Room](http://jamrogue.lemmmy.pw/red.png) Loot Rooms
Loot rooms, seen as Treasuries, Storage Rooms, Armouries or Abandoned Camps; these big rooms contain a large amount of chests.

### ![Red Room](http://jamrogue.lemmmy.pw/red.png) Camps
These large camps contain two to six Goblins or Dwarves - be ready for these!

### ![Red Room](http://jamrogue.lemmmy.pw/red.png) Bosses
These large Boss rooms contain two or three Lizards or Serpents, as well as one to three locked chests. They are tough.

## Mobs

###Rat
![Rat](http://jamrogue.lemmmy.pw/rat.png)<br />
**Health:** 2.0<br />
**Damage:** 1.0<br />
**Damage Ticks:** 15<br />
**Critical Hit Chance:** 0%<br />
**Critical Hit Multiplier:** 1.0x<br />
**Drops:** Poop, *throwables*, *projectiles*<br />

###Bat
![Bat](http://jamrogue.lemmmy.pw/bat.png)<br />
**Health:** 2.0<br />
**Damage:** 1.0<br />
**Damage Ticks:** 12<br />
**Critical Hit Chance:** 0%<br />
**Critical Hit Multiplier:** 1.0x<br />
**Drops:** *throwables*, *projectiles*<br />

###Goblin
![Goblin](http://jamrogue.lemmmy.pw/goblin.png)<br />
**Health:** 5.0<br />
**Damage:** 1.0<br />
**Damage Ticks:** 15<br />
**Critical Hit Chance:** 25%<br />
**Critical Hit Multiplier:** 2.0x<br />
**Drops:** *melee*, *throwables*, *projectiles*<br />

###Dwarf
![Dwarf](http://jamrogue.lemmmy.pw/dwarf.png)<br />
**Health:** 5.0<br />
**Damage:** 2.0<br />
**Damage Ticks:** 20<br />
**Critical Hit Chance:** 20%<br />
**Critical Hit Multiplier:** 2.0x<br />
**Drops:** *shooters*, *projectiles*<br />

###Lizard
![Lizard](http://jamrogue.lemmmy.pw/lizard.png)<br />
**Health:** 8.0<br />
**Damage:** 2.0<br />
**Damage Ticks:** 30<br />
**Critical Hit Chance:** 20%<br />
**Critical Hit Multiplier:** 2.0x<br />
**Drops:** *consumables*<br />

###Serpent
![Serpent](http://jamrogue.lemmmy.pw/serpent.png)<br />
**Health:** 7.0<br />
**Damage:** 3.0<br />
**Damage Ticks:** 30<br />
**Critical Hit Chance:** 10%<br />
**Critical Hit Multiplier:** 2.0x<br />
**Drops:** *consumables*<br />

## Item Rarities
![Common](http://jamrogue.lemmmy.pw/common.png)<br />
**Minimum Level:** Level 1<br />
**Damage Multiplier:** 1.0x<br /><br />
![Regular](http://jamrogue.lemmmy.pw/regular.png)<br />
**Minimum Level:** Level 2<br />
**Damage Multiplier:** 1.2x<br /><br />
![Superb](http://jamrogue.lemmmy.pw/superb.png)<br />
**Minimum Level:** Level 4<br />
**Damage Multiplier:** 1.5x<br /><br />
![Rare](http://jamrogue.lemmmy.pw/rare.png)<br />
**Minimum Level:** Level 6<br />
**Damage Multiplier:** 2.0x<br /><br />
![Legendary](http://jamrogue.lemmmy.pw/legendary.png)<br />
**Minimum Level:** Level 8<br />
**Damage Multiplier:** 3.0x<br /><br />
![Exalted](http://jamrogue.lemmmy.pw/exalted.png)<br />
**Minimum Level:** Level 10<br />
**Damage Multiplier:** 4.0x<br /><br />
![Epic](http://jamrogue.lemmmy.pw/epic.png)<br />
**Minimum Level:** Level 15<br />
**Damage Multiplier:** 5.0x<br /><br />

## Items

###Rusty Sword (melee)
*It's a Rusty Sword, looks pretty old.*<br />
**Minimum Level:** Level 1<br />
**Damage:** 1

###Club (melee)
*Some sort of Club from somewhere.*<br />
**Minimum Level:** Level 1<br />
**Damage:** 1

###Stick (melee)
*It's a Stick but do we even have trees down here?*<br />
**Minimum Level:** Level 1<br />
**Damage:** 1

###Branch (melee)
*It's a Branch - is this really any better than a stick?*<br />
**Minimum Level:** Level 2<br />
**Damage:** 2

###Knife (melee)
*Equally useful in the kitchen and the dungeon.*<br />
**Minimum Level:** Level 5<br />
**Damage:** 3

###Sword (melee)
*It's a Sword, looks sturdy.*<br />
**Minimum Level:** Level 5<br />
**Damage:** 3

###Shortsword (melee)
*It's a Shortsword, short and swift.*<br />
**Minimum Level:** Level 10<br />
**Damage:** 4

###Longsword (melee)
*It's a Longsword.*<br />
**Minimum Level:** Level 13<br />
**Damage:** 5


----------


###Rock (throwable)
*Just a rock.*<br />
**Minimum Level:** Level 1<br />
**Damage:** 1<br />
**Range:** 6<br />
**Maximum Stack:** 8

###Brick (throwable)
*Just a brick.*<br />
**Minimum Level:** Level 1<br />
**Damage:** 1<br />
**Range:** 5<br />
**Maximum Stack:** 10

###Can (throwable)
*Just a can.*<br />
**Minimum Level:** Level 1<br />
**Damage:** 1.0<br />
**Range:** 0<br />
**Maximum Stack:** 20

###Boulder (throwable)
*How do you carry this?.*<br />
**Minimum Level:** Level 1<br />
**Damage:** 5.0<br />
**Range:** 6<br />
**Maximum Stack:** 3


----------


###Slingshot (shooter)
*It's a Slingshot - looks like it requires pebbles.*<br />
**Minimum Level:** Level 1<br />
**Range:** 8<br />
**Projectiles:** Pebble

###Flismy Bow (shooter)
*It's a Flimsy Bow.*<br />
**Minimum Level:** Level 2<br />
**Range:** 12<br />
**Projectiles:** Arrow

###Bow (shooter)
*It's a Bow.*<br />
**Minimum Level:** Level 5<br />
**Range:** 15<br />
**Projectiles:** Arrow

###Strong Bow (shooter)
*It's a Strong Bow.*<br />
**Minimum Level:** Level 10<br />
**Range:** 18<br />
**Projectiles:** Arrow

###Crossbow (shooter)
*It's a Strong Bow.*<br />
**Minimum Level:** Level 12<br />
**Range:** 20<br />
**Projectiles:** Arrow


----------


###Pebble (projectile)
*Might be useful for a slingshot or something.*<br />
**Minimum Level:** Level 1<br />
**Damage:** 1<br />
**Maximum Stack:** 30

###Arrow (projectile)
*Sharp and pointy.*<br />
**Minimum Level:** Level 2<br />
**Damage:** 2.0<br />
**Maximum Stack:** 30

###Venom Arrow (projectile)
*Sharp, pointy and venomous.*<br />
**Minimum Level:** Level 6<br />
**Damage:** 4.0<br />
**Maximum Stack:** 30


----------


###Apple (consumable)
*An apple a day keeps the doctor away.*<br />
**Minimum Level:** Level 1<br />
**Heals:** 2.0<br />
**Maximum Stack:** 6

###Water Bottle (consumable)
*It's healthier than soda.*<br />
**Minimum Level:** Level 1<br />
**Heals:** 1.0

###Poop (consumable)
*You really don't want to eat this.*<br />
**Minimum Level:** Level 1<br />
**Heals:** 1.0<br />
**Maximum Stack:** 15

###Pineapple (consumable)
*A pineapple a day keeps the monsters away.*<br />
**Minimum Level:** Level 2<br />
**Heals:** 3.0<br />
**Maximum Stack:** 4

###Health Potion (consumable)
*Looks suspicious, but it says health on it!*<br />
**Minimum Level:** Level 4<br />
**Heals:** 5.0

###Health Vial (consumable)
*Looks suspicious, but it says health on it!*<br />
**Minimum Level:** Level 6<br />
**Heals:** 8.0

###Cake (consumable)
*Lucky find.*<br />
**Minimum Level:** Level 8<br />
**Heals:** 10.0


----------


###Chest Key (misc)
*A flimsy key that probably only works once.*<br />
**Minimum Level:** Level 1


----------


# Contributing
Please suggest features and submit bug reports to the [Issues](https://github.com/Lemmmy/CCJam-2016/issues) page. As well as this, there are sometimes [Votes](https://github.com/Lemmmy/CCJam-2016/issues?q=is%3Aopen+is%3Aissue+label%3Avote) and [Suggestion Requests](https://github.com/Lemmmy/CCJam-2016/issues?q=is%3Aopen+is%3Aissue+label%3A%22open+to+suggestions%22) open that you can contribute to to help the development of jamROGUE.

There may also be open issues [asking for help](https://github.com/Lemmmy/CCJam-2016/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22), be sure to check those out too.


----------


# Server
The server-side of jamROGUE is written in Node.js. It uses ES2015, and is compiled with Babel. IT requires MongoDB for the database, and uses Express.js for the webserver.

## Installation (Linux)

### Dependencies
jamROGUE depends on MongoDB, Node.js and optionally nginx as a reverse proxy. You can look up the installation of these for your distro of choice.

### Building
jamROGUE uses Gulp for building. Install gulp globally through npm if you haven't already, and then simply run `gulp babel` to build the files into the `dist` directory.

### Configuration
To configure the server, create a `config.json` file in the `dist` directory (or wherever you compiled the code to). It needs to contain the fields `mongodbURI` (the URI to connect to MongoDB) and `listen` (the port or sock file to listen to).

**Example:**

	{
		"mongodbURI": "mongodb://localhost/jamrogue",
		"listen": "/var/socks/jamrogue.sock"
	}

### Running
When you have built and configured the server, you can run it with `node main` in the `dist` directory (or wherever you compiled the code to). You can run this in a screen, or run it as a `forever` process, or anything else.

**Important:** Whenever the server starts, it will generate the world. This is a very CPU intensive process that can take several minutes. If you wish to use a smaller world, change the `roomCount`, `hubRatio`, `ellipseWidth` and `ellipseHeight` variables in `src/dungeon.js` then re-compile the code with `gulp babel`.


----------


# License
The client and server code are licensed under GPLv3. For more information see the [LICENSE](https://github.com/Lemmmy/jamROGUE/blob/master/LICENSE) file.