class GenClass {
	public static function gen(c: ClassInfo): { path: String, contents: String } {
		var hx = 'package lovr.${c.name};\n\n';
		var cname = c.name.charAt(0).toUpperCase() + c.name.substr(1);
		hx += 'extern class ${cname} {\n';
		for (f in c.functions) {
			hx += '\t@:native("${f.full}")\n';

			var ret = "Void";
			var first = true;
			for (v in f.variants) {
				if (!first) {
					// hx += "@:overload(function (color:Table<Dynamic,Dynamic>, stencilvalue: Int, depthvalue: Float) : Void {})"
				}
				first = false;

				if (v.returns.length > 1) {
					continue;
				}
				if (v.returns.length == 1) {
					ret = switch (v.returns[0].type) {
						case "number": "Float";
						default: "Void";
					}
				}
				var args = "";
				for (i in 0...v.arguments.length) {
					var arg = v.arguments[i];
					args += arg;
					if (i < v.arguments.length) {
						args += ",";
					}
				}
				hx += '\tfunction ${f.name}(${args}): ${ret} {}\n';
			}
		}
		hx += '}\n';

		return {
			path: 'lovr/${cname}.hx',
			contents: hx
		}
	}
}
