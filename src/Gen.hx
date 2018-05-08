import haxe.Http;
import haxe.Json;

typedef ArgInfo = {
	name: String,
	type: String
}

typedef VariantInfo = {
	arguments: Array<ArgInfo>,
	returns: Array<ArgInfo>
}

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
				arguments: Array<{
					type: String,
					name: String
				}>,
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

typedef ApiInfo = {
	modules: Array<ClassInfo>,
	objects: Array<Int>,
	enums: Array<Int>
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

	static function convert(parsed: LovrApi): ApiInfo {
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
					var variant: VariantInfo = {
						arguments: [],
						returns: []
					}
					for (arg in v.arguments) {
						variant.arguments.push({
							name: arg.name,
							type: arg.type
						});
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
		return {
			modules: classes,
			objects: [],
			enums: [],
		};
	}

	static function main() {
		var data = feed("api.json");
		if (data == null) {
			return;
		}
		var parsed: LovrApi = Json.parse(data);
		var info = convert(parsed);
		var tree = [];
		for (c in info.modules) {
			var generated = GenClass.gen(c);
			tree.push(generated.path);
			var output = sys.io.File.write(generated.path);
			var dir = haxe.io.Path.directory(generated.path);
			if (!sys.FileSystem.isDirectory(dir)) {
				try {
					sys.FileSystem.createDirectory(dir);
					Sys.println('created $dir');
				}
				catch (e: Dynamic) {
					trace(e);
				}
			}
			output.writeString(generated.contents);
			output.close();
			Sys.println('generated ${generated.path}');
		}
	}
}
