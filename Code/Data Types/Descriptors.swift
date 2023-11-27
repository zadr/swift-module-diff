import Foundation

protocol Attributed {
	var attributes: Set<Attribute> { get }
}

protocol Decorated {
	var decorators: Set<Member.Decorator> { get }
}

protocol Named {
	var name: String { get }
}

protocol Displayable {
	var developerFacingName: String { get }
}
