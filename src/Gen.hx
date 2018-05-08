import haxe.Http;
import haxe.Json;


typedef LovrApi = {
	callbacks: Array<{

	}>,
	modules: Array<{
		summary: String,
		enums: Array<{
			summary: String,
			module: String,
			values: Array<{
				name: String,
				description: String
			}>,
			key: String,
			name: String,
			description: String
		}>,
		objects: {},
		examples: Array<{
			code: String,
			description: String
		}>,
		sections: Array<{
			tag: String,
			name: String,
			description: String
		}>,
		key: String,
		external: Bool,
		tag: String,
		functions: Array<{
			summary: String,
			module: String,
			variants: Array<{
				arguments: Array<{}>,
				returns: Array<{
					type: String,
					name: String,
					description: String
				}>
			}>,
			tag: String,
			name: String,
			key: String,
			description: String
		}>,
		name: String,
		description: String
	}>
}

class Gen {
	static function feed(filename: String): String {
		var data: String;
		if (sys.FileSystem.exists(filename)) {
			var input = sys.io.File.read(filename);
			if (input == null) {
				Sys.println("unable to load lovr api");
				Sys.exit(1);
				return null;
			}
			data = input.readAll().toString();
		}
		else {
			data = Http.requestUrl("https://lovr.org/api/data");
			if (data == null) {
				Sys.println("unable to download lovr api");
				Sys.exit(1);
				return null;
			}
			var output = sys.io.File.write(filename);
			output.writeString(data);
			output.close();
		}
		return data;
	}

	static function convert(parsed: LovrApi): Array<ClassInfo> {
		var classes: Array<ClassInfo> = [];
		for (m in parsed.modules) {
			var classinfo = {
				name: m.name,
				functions: []
			}
			for (f in m.functions) {
				var fn = {
					name: f.name,
					full: f.key,
					variants: []
				}
				for (v in f.variants) {
					var variant = {
						arguments: [],
						returns: []
					}
					for (arg in v.arguments) {
						// variant.arguments.push({
						// 	name: arg.name,
						// 	type: arg.type
						// });
					}
					for (ret in v.returns) {
						variant.returns.push({
							name: ret.name,
							type: ret.type
						});
					}
					fn.variants.push(variant);
				}
				classinfo.functions.push(fn);
			}
			classes.push(classinfo);
		}
		return classes;
	}

	static function main() {
		var data = feed("api.json");
		if (data == null) {
			return;
		}
		var parsed: LovrApi = Json.parse(data);
		var classes = convert(parsed);
		var tree = [];
		for (c in classes) {
			var generated = GenClass.gen(c);
			tree.push(generated.path);
			trace(generated.path);
			trace(generated.contents);
		}
		for (path in tree) {
			trace(path);
		}
	}
}
