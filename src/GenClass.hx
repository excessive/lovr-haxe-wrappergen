class GenClass {
	static function convert_type(types: Map<String, ObjectInfo>, sig: String): String {
		if (types.exists(sig)) {
			return sig;
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
					args += '${arg.name}: ${convert_type(types, arg.type)}';
				}
				if (i < v.arguments.length-1) {
					args += ", ";
				}
			}
			sigs.push('(${args}): ${ret} {}');
		}

		if (sigs.length > 1) {
			for (i in 1...sigs.length) {
				hx += '\t@:overload(function ${sigs[i]})\n';
			}
		}
		hx += '\t${is_static ? "static " : ""}function ${f.name}${sigs[0]}\n';

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
			var sig = '(${args.join("->")})->$ret';
			hx += '\tstatic var ${v.name}: ${sig};\n';
		}
		for (f in c.functions) {
			hx += emit_fn(types, f, true);
		}
		for (f in c.methods) {
			hx += emit_fn(types, f, false);
		}
		hx += '}\n';

		return {
			path: 'lovr/${c.name}.hx',
			contents: hx
		}
	}
}
