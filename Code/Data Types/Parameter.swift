import Foundation

struct Parameter: Hashable {
	var name: String = ""
	var type: String = ""
	var isInout: Bool = false
	var attributes: Set<String> = .init()
}
