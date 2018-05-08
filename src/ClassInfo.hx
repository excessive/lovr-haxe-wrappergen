typedef ClassInfo = {
	name: String,
	full: String,
	functions: Array<{
		name: String,
		variants: Array<{
			arguments: Array<{
				name: String,
				type: String
			}>,
			returns: Array<{
				name: String,
				type: String
			}>
		}>
	}>
}
