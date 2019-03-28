class GenClass {
	static function fix_caps(str: Null<String>) {
		if (str == null) {
			return str;
		}
		return str.toUpperCase().substring(0, 1) + str.substring(1, str.length);
	}

	static function convert_type(types: Map<String, ObjectInfo>, sig: String): String {
		if (sig == null) {
			throw "NO!!";
		}
		if (types.exists(sig)) {
			return fix_caps(sig);
		}
		return switch (sig) {
			case "function": "Void->Void"; // no info in docs about function arguments.
			case "boolean": "Bool";
			case "string": "String";
			case "number": "Float";
			case "table": "lua.Table<Dynamic, Dynamic>";
			case "*": "Dynamic";
			default: "Dynamic";
		}
	}

	static var header = "\n#if (!lua && !display)\n#error \"lovr can only be used with lua!\"\n#end\n\n";

	static function emit_fn(types, f: {variants: Array<VariantInfo>, name: String}, is_static: Bool) {
		var hx = "";
		var ret = "Void";
		var sigs = [];
		for (v in f.variants) {
			if (v.returns.length > 1) {
				// TODO: multiret support
				v.returns = [ v.returns[0] ];
				// continue;
			}
			if (v.returns.length == 1) {
				ret = convert_type(types, v.returns[0].type);
			}
			else {
				ret = "Void";
			}
			var args = "";
			for (i in 0...v.arguments.length) {
				var arg = v.arguments[i];
				if (arg.optional) {
					args += "?";
				}
				if (arg.name == "...") {
					args += 'args: haxe.extern.Rest<${convert_type(types, arg.type)}>';
				}
				else {
					if (arg.type == null) {
						arg.type = "Dynamic";
					}
					args += '${arg.name}: ${convert_type(types, arg.type)}';
				}
				if (i < v.arguments.length-1) {
					args += ", ";
				}
			}
			sigs.push('(${args}): ${ret}');
		}

		for (i in 1...sigs.length) {
			hx += '\t@:overload(function ${sigs[i]} {})\n';
		}
		hx += '\t${is_static ? "static " : ""}function ${f.name}${sigs[0]};\n';

		return hx;
	}

	public static function gen(c: ClassInfo, types: Map<String, ObjectInfo>): { path: String, contents: String } {
		var hx = 'package lovr;\n';
		hx += header;

		hx += '@:native("${c.full}")\n';
		var ext = "";
		if (c.extend != null) {
			ext = 'extends ${c.extend} ';
		}

		c.name = fix_caps(c.name);
		hx += 'extern class ${c.name} ${ext}{\n';
		for (v in c.vars) {
			var ret = "Void";
			if (v.type.returns.length > 0) {
				ret = convert_type(types, v.type.returns[0].type);
			}
			var args = [ "Void" ];
			if (v.type.arguments.length > 0) {
				args = [];
				for (arg in v.type.arguments) {
					args.push(convert_type(types, arg.type));
				}
			}
			var sig = '${args.join("->")}->$ret';
			hx += '\tstatic var ${v.name}: ${sig};\n';
		}
		for (f in c.functions) {
			if (f.name.lastIndexOf("__") >= 0) {
				continue;
			}
			hx += emit_fn(types, f, true);
		}
		for (f in c.methods) {
			// skip metamethods
			if (f.name.lastIndexOf("__") >= 0) {
				// trace(f.name);
				continue;
			}
			hx += emit_fn(types, f, false);
		}
		hx += '}\n';

		return {
			path: 'lovr/${c.name}.hx',
			contents: hx
		}
	}
}
