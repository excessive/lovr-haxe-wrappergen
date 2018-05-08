import haxe.Http;
import haxe.Json;

typedef LovrVariantInfo = {
	arguments: Array<{
		name: String,
		type: String,
		description: String
	}>,
	returns: Array<{
		name: String,
		type: String,
		description: String
	}>
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
		objects: Array<{
			summary: String,
			module: String,
			methods: Array<{
				summary: String,
				module: String,
				variants: Array<LovrVariantInfo>,
				key: String,
				name: String,
				description: String
			}>,
			constructors: Array<String>,
			key: String,
			name: String,
			description: String
		}>,
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
			variants: Array<LovrVariantInfo>,
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
	types: Map<String, ObjectInfo>,
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

	static function convert_variants(base: Array<LovrVariantInfo>): Array<VariantInfo> {
		var variants: Array<VariantInfo> = [];
		for (v in base) {
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
			variants.push(variant);
		}
		return variants;
	}

	static function convert(parsed: LovrApi): ApiInfo {
		var classes: Array<ClassInfo> = [];
		var types = new Map<String, ObjectInfo>();

		for (m in parsed.modules) {
			var classinfo = {
				name: m.name.charAt(0).toUpperCase() + m.name.substr(1),
				full: m.key,
				functions: [],
				methods: []
			}
			for (o in m.objects) {
				var objdef = {
					name: o.name,
					methods: []
				}
				for (method in o.methods) {
					objdef.methods.push({
						name: method.name,
						variants: convert_variants(method.variants)
					});
				}
				types[o.name] = objdef;
				classes.push({
					name: o.name,
					full: o.key,
					functions: [],
					methods: objdef.methods
				});
			}
			for (f in m.functions) {
				classinfo.functions.push({
					name: f.name,
					variants: convert_variants(f.variants)
				});
			}
			classes.push(classinfo);
		}
		for (cb in parsed.callbacks) {
			//
		}
		return {
			modules: classes,
			types: types,
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
			var generated = GenClass.gen(c, info.types);
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
