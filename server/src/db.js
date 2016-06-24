import Rethink from "rethinkdbdash";
import Promise from "bluebird";

let DB = {
	init(config) {
		return new Promise(resolve => {
			DB.r = Rethink({
				servers: [{
					host: config.rethinkHost,
					port: config.rethinkPort,
					db: config.rethinkDB,
					user: config.rethinkUser,
					password: config.rethinkPass
				}]
			});

			resolve();
		});
	}
};

export default DB;