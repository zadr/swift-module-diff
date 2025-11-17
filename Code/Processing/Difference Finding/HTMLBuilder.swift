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

// reference https://github.com/Kitura/swift-html-entities/blob/master/Sources/HTMLEntities/Utilities.swift
extension UInt32 {
	var isASCII: Bool { self < 0x80 }
	var isASCIIAndNotEscapeCharacter: Bool {
		isASCII && // is ascii
			(self != 0x22 && self != 0x27) && // is not a " or a '
			(self != 0x26) && // is not an &
			(self != 0x3C && self != 0x3E) // is not a < or a >
	}

}

// reference https://github.com/Kitura/swift-html-entities/blob/master/Sources/HTMLEntities/String%2BHTMLEntities.swift
extension String {
	func htmlEscape() -> String {
		map { c in
			let unicodes = String(c).unicodeScalars

			// inline the common case to be fast
			if unicodes.count == 1, let unicode = unicodes.first?.value, unicode.isASCII || unicode.isASCIIAndNotEscapeCharacter {
				return String(c)
			}

			// handle each component of a glyph individually
			return unicodes.map { scalar in
				let unicode = scalar.value

				if unicode.isASCIIAndNotEscapeCharacter {
					return String(scalar)
				}

				return "&#\(String(unicode, radix: 16, uppercase: true));"
			}.joined()
		}.joined()
	}
}
