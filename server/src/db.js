import mongoose, {Schema} from "mongoose";
import Promise from "bluebird";

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
					dungeonID: Number,
					room: Number,
					x: Number,
					y: Number,
					visitedRooms: Array,
					items: Array,
					money: Number,
					xp: Number,
				});

				userSchema.set("toJSON", {
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