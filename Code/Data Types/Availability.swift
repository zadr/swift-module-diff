import Foundation

enum Availability: Equatable, Hashable {
	case platform(name: String, version: String)
	case unavailablePlatform(name: String)
	case any
}
