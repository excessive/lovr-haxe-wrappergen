class GenClass {
	static function convert_type(sig: String): String {
		return switch (sig) {
			case "string": "String";
			case "number": "Float";
			case "table": "lua.Table<Dynamic, Dynamic>";
			case "*": "Dynamic";
			default: "Dynamic";
		}
	}

	static var header = "\n#if (!lua && !display)\n#error \"lovr can only be used with lua!\"\n#end\n\n";

	public static function gen(c: ClassInfo): { path: String, contents: String } {
		var hx = 'package lovr;\n';
		hx += header;
		var cname = c.name.charAt(0).toUpperCase() + c.name.substr(1);
		hx += 'extern class ${cname} {\n';
		for (f in c.functions) {
			hx += '\t@:native("${f.full}")\n';

			var ret = "Void";
			var first = true;
			for (v in f.variants) {
				if (v.returns.length > 1) {
					// TODO: multiret support
					v.returns = [ v.returns[0] ];
					// continue;
				}
				if (v.returns.length == 1) {
					ret = convert_type(v.returns[0].type);
				}
				else {
					ret = "Void";
				}
				var args = "";
				for (i in 0...v.arguments.length) {
					var arg = v.arguments[i];
					if (arg.name == "...") {
						args += 'args: haxe.extern.Rest<${convert_type(arg.type)}>';
					}
					else {
						args += '${arg.name}: ${convert_type(arg.type)}';
					}
					if (i < v.arguments.length-1) {
						args += ", ";
					}
				}
				if (first) {
					hx += '\tfunction ${f.name}(${args}): ${ret} {}\n';
				}
				else {
					// hx += "@:overload(function (color:Table<Dynamic,Dynamic>, stencilvalue: Int, depthvalue: Float) : Void {})"
				}
				first = false;
			}
		}
		hx += '}\n';

		return {
			path: 'lovr/${cname}.hx',
			contents: hx
		}
	}
}
