typedef ClassInfo = {
	name: String,
	full: String,
	extend: String,
	functions: Array<{
		name: String,
		variants: Array<VariantInfo>
	}>,
	methods: Array<{
		name: String,
		variants: Array<VariantInfo>
	}>,
	vars: Array<{
		name: String,
		type: VariantInfo
	}>
}
