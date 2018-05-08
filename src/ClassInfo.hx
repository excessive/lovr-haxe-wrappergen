typedef ClassInfo = {
	name: String,
	functions: Array<{
		name: String,
		full: String,
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
