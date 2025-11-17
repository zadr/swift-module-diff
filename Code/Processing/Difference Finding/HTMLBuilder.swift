@resultBuilder
struct HTMLBuilder {
	static func buildBlock(_ components: String...) -> String {
		components.joined()
	}
}

func html(lang: String? = nil, @HTMLBuilder content: () -> String) -> String {
	let langAttr = lang.map { " lang=\"\($0)\"" } ?? ""
	return "<!DOCTYPE html>\n<html\(langAttr)>\n\(content())</html>\n"
}

func head(@HTMLBuilder content: () -> String) -> String {
	"<head>\n\(content())</head>\n"
}

func body(@HTMLBuilder content: () -> String) -> String {
	"<body>\n\(content())</body>\n"
}

func meta(charset: String) -> String {
	"<meta charset=\"\(charset)\">\n"
}

func meta(name: String, content: String) -> String {
	"<meta name=\"\(name.htmlEscape())\" content=\"\(content.htmlEscape())\">\n"
}

func meta(property: String, content: String) -> String {
	"<meta property=\"\(property.htmlEscape())\" content=\"\(content.htmlEscape())\">\n"
}

func link(rel: String, href: String) -> String {
	"<link rel=\"\(rel.htmlEscape())\" href=\"\(href.htmlEscape())\">\n"
}

func style(@HTMLBuilder content: () -> String) -> String {
	"<style>\n\(content())</style>\n"
}

func script(@HTMLBuilder content: () -> String) -> String {
	"<script>\n\(content())</script>\n"
}

func div(id: String? = nil, class classAttr: String? = nil, @HTMLBuilder content: () -> String) -> String {
	var attrs = [String]()
	if let id { attrs.append("id=\"\(id.htmlEscape())\"") }
	if let classAttr { attrs.append("class=\"\(classAttr.htmlEscape())\"") }
	let attrString = attrs.isEmpty ? "" : " " + attrs.joined(separator: " ")
	return "<div\(attrString)>\(content())</div>\n"
}

func tag(_ name: String, @HTMLBuilder content: () -> String) -> String {
	"<\(name)>\(content().htmlEscape())</\(name)>\n"
}
