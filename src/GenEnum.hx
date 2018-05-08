class GenEnum {
	public static function gen(e: EnumInfo): { path: String, contents: String } {
		var hx = "package lovr;\n\n";
		
		hx += 'enum abstract ${e.name}(String) {\n';

		for (v in e.values) {
			hx += '\tvar ${v} = "${v}";\n';
		}

		hx += '}\n';

		return {
			path: 'lovr/${e.name}.hx',
			contents: hx
		}
	}
}
