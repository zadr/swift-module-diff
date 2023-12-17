import Foundation

extension Summarizer {
	static func htmlVisitor(from fromVersion: Version, to toVersion: Version, root: String) -> ChangeVisitor {
		var html = ""
		return ChangeVisitor(
			willBegin: {
				let title = "swiftmodule \(fromVersion.name) to Xcode \(toVersion.name) Diff"
				let description = "API changes between Xcode \(fromVersion.name) and Xcode \(toVersion.name)"

				print("starting html")
				html += """
<!DOCTYPE html>
<head>
	<meta charset="utf-8">
	<title>\(title)</title>
	<meta name="generator" content="swiftmodule-diff">
	<meta property="og:title" content="\(title)">
	<meta property="og:locale" content="en_US">
	<meta name="description" content"\(description)"=>
	<meta property="og:description" content="\(description)™">
	<link rel="canonical" href="https://example.com/">
	<meta property="og:url" content="https://example.com/">
	<meta property="og:site_name" content="example.com">
	<meta property="og:type" content="website">
</head>
<html lang="en-US">
"""
			},
			didEnd: {
html += """
</html>
"""
				let path = ("\(root)/swiftmodule-diff-\(fromVersion.name)-to-\(toVersion.name).html" as NSString).expandingTildeInPath
				try! html.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
			},
			willVisitPlatform: { change in
				html += """

	<details id="\(change.any.name)">
		<summary>
			\(change.kind) \(change.any.name)
"""
//				  <details id="x">
//					<summary>X</summary>
//					Long text about x.
//				  </details>
//				<a href="#x>Go to X</a>
			},
			didVisitPlatform: { change in
				html += """
		</summary>
	</details>
"""
			},
			willVisitArchitecture: { change in
				html += """
	<details id="\(change.any.name)">
		<summary>
			\(change.kind) \(change.any.name)
"""
			},
			didVisitArchitecture: { change in
				html += """
		</summary>
	</details>
"""
			},
			willVisitFramework: { change in
				html += """
	<details id="\(change.any.name)">
		<summary>
			\(change.kind) \(change.any.name)
"""
			},
			didVisitFramework: { change in
				html += """
		</summary>
	</details>
"""
			},
			willVisitDependency: { change in
				html += """
	<details id="\(change.any.name)">
		<summary>
			\(change.kind) \(change.any.developerFacingValue)
"""
			},
			didVisitDependency: { change in
				html += """
		</summary>
	</details>
"""
			},
			willVisitNamedType: { change in
				html += """
	<details id="\(change.any.name)">
		<summary>
			\(change.kind) \(change.any.developerFacingValue)
"""
			},
			didVisitNamedType: { change in
				html += """
		</summary>
	</details>
"""
			},
			willVisitMember: { change in
				html += """
	<details id="\(change.any.name)">
		<summary>
			\(change.kind) \(change.any.developerFacingValue)
"""
			},
			didVisitMember: { change in
				html += """
		</summary>
	</details>
"""
			}
		)
	}
}
