import mongoose, {Schema} from "mongoose";
import Promise from "bluebird";

import _ from "lodash";

let DB = {
	models: {},

	init(config) {
		return new Promise(resolve => {
			mongoose.Promise = Promise;
			mongoose.connect(config.mongodbURI);
			DB.m = mongoose.connection;

			DB.m.on("error", console.error.bind(console, "Poop: "));

			DB.m.once("open", () => {
				let userSchema = mongoose.Schema({
					name: String,
					password: String,
					dungeonID: String,
					room: Number,
					x: Number,
					y: Number,
					visitedRooms: Array,
					inventory: Array,
					money: Number,
					xp: Number,
					alive: Boolean,
					level: {
						type: Number,
						default: 1
					},
					health: {
						type: Number,
						default: 5
					},
					created: {
						type: Date,
						default: Date.now
					}
				});

				userSchema.set("serialize", {
					transform: (doc, user) => {
						return _.omit(user, "password");
					}
				});

				DB.models.User = mongoose.model("User", userSchema);

				resolve();
			});
		});
	}
};

export default DB;