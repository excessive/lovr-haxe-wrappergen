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
		name: String,
		variants: Array<VariantInfo>
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
		if (!sys.FileSystem.exists("lovr")) {
			sys.FileSystem.createDirectory("lovr");
		}
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
			if (m.external) {
				continue;
			}
			var classinfo = {
				name: m.name.charAt(0).toUpperCase() + m.name.substr(1),
				full: m.key,
				functions: [],
				methods: [],
				vars: [],
				extend: null
			}
			for (o in m.objects) {
				var objdef = {
					name: o.name,
					methods: []
				}
				// haxe doesn't let you use keywords as field names naturally
				var ext: String = null;
				if (Reflect.hasField(o, "extends")) {
					ext = Reflect.getProperty(o, "extends");
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
					extend: ext,
					functions: [],
					vars: [],
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
		var lovr = classes.filter((info) -> return info.name == "Lovr")[0];
		for (cb in parsed.callbacks) {
			lovr.vars.push({
				name: cb.name,
				type: cb.variants[0]
			});
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
