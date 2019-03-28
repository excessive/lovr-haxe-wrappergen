class GenEnum {
	static function mangle(s: String) {
		var prefix = "";
		if (Std.parseInt(s.charAt(0)) != null) {
			prefix = "_";
		}
		return prefix + s.charAt(0).toUpperCase() + s.substr(1);
	}

	public static function gen(e: EnumInfo): { path: String, contents: String } {
		var hx = "package lovr;\n\n";
		
		hx += 'enum abstract ${e.name}(String) {\n';

		for (v in e.values) {
			hx += '\tvar ${mangle(v)} = "${v}";\n';
		}

		hx += '}\n';

		return {
			path: 'lovr/${e.name}.hx',
			contents: hx
		}
	}
}
