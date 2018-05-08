typedef ClassInfo = {
	name: String,
	full: String,
	functions: Array<{
		name: String,
		variants: Array<VariantInfo>
	}>,
	methods: Array<{
		name: String,
		variants: Array<VariantInfo>
	}>
}
