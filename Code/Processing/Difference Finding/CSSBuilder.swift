@resultBuilder
struct CSSBuilder {
	static func buildBlock(_ components: String...) -> String {
		components.joined()
	}
}

func cssRule(_ selector: String, @CSSBuilder properties: () -> String) -> String {
	"\(selector) {\n\(properties())}\n\n"
}

func property(_ name: String, _ value: String) -> String {
	"\t\(name): \(value);\n"
}

func properties(_ pairs: (String, String)...) -> String {
	pairs.map { "\t\($0.0): \($0.1);\n" }.joined()
}
