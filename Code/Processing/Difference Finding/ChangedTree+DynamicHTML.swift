import Foundation
import HTMLEntities

extension ChangedTree {
	static func dynamicHTMLVisitor(from fromVersion: Version, to toVersion: Version, root: String) -> ChangeVisitor {
		ChangeVisitor(
			didEnd: { tree in
				let title = "Xcode \(fromVersion.name) to Xcode \(toVersion.name) Diff"
				let description = "API changes between Xcode \(fromVersion.name) and Xcode \(toVersion.name)"

				// Convert tree to JSON (minified)
				let interestingTree = tree.notableDifferences()
				let encoder = JSONEncoder()
				encoder.keyEncodingStrategy = .convertToSnakeCase
				let jsonData = try! encoder.encode(interestingTree)
				let jsonString = String(data: jsonData, encoding: .utf8)!

				// Escape the JSON for embedding in JavaScript
				let escapedJSON = jsonString
					.replacingOccurrences(of: "\\", with: "\\\\")
					.replacingOccurrences(of: "`", with: "\\`")
					.replacingOccurrences(of: "$", with: "\\$")

				let document = html(lang: "en-US") {
					head {
						meta(charset: "utf-8")
						tag("title") { title }
						meta(name: "generator", content: "swiftmodule-diff")
						meta(property: "og:title", content: title)
						meta(property: "og:locale", content: "en_US")
						meta(name: "description", content: description)
						meta(property: "og:description", content: description)
						meta(property: "og:url", content: "https://example.com/")
						meta(property: "og:site_name", content: "example.com")
						meta(property: "og:type", content: "website")
						link(rel: "canonical", href: "https://example.com/")
						style {
							"""
							a {
								color: black;
							}

							ul {
								list-style: none;
							}

							li.added:before {
								content: "➕";
								padding-right: 5px;
							}

							li.modified:before {
								content: "〰️";
								padding-right: 5px;
							}

							li.removed:before {
								content: "➖";
								padding-right: 5px;
							}

							span.added {
								color: #22863a;
								background-color: #f0fff4;
								padding: 2px 4px;
								border-radius: 3px;
							}

							span.removed {
								color: #cb2431;
								background-color: #ffeef0;
								padding: 2px 4px;
								border-radius: 3px;
								text-decoration: line-through;
							}

							details {
								border: 1px solid #aaa;
								border-radius: 4px;
								padding: 0.5em;
								margin: 0.5em 0;
							}

							summary {
								font-weight: bold;
								padding: 0.5em;
								cursor: pointer;
							}

							.tabs {
								margin: 20px 0;
							}

							.tab-buttons {
								display: flex;
								gap: 0;
								border-bottom: 2px solid #ccc;
								margin-bottom: 20px;
							}

							.tab-button {
								background: #f5f5f5;
								border: 1px solid #ccc;
								border-bottom: none;
								padding: 10px 20px;
								cursor: pointer;
								font-size: 16px;
								border-radius: 4px 4px 0 0;
								margin-bottom: -2px;
							}

							.tab-button:hover {
								background: #e8e8e8;
							}

							.tab-button.active {
								background: white;
								border-bottom: 2px solid white;
								font-weight: bold;
								z-index: 1;
							}

							.tab-content {
								display: none;
							}

							.tab-content.active {
								display: block;
							}
							"""
						}
					}
					body {
						div(id: "app") { "Loading..." }
						script {
							"""
							const data = JSON.parse(`\(escapedJSON)`);

							function escapeHtml(text) {
								const div = document.createElement('div');
								div.textContent = text;
								return div.innerHTML;
							}

							function renderMembers(members) {
								if (!members || members.length === 0) return '';

								const filteredMembers = members.filter(m => m.change !== 'unchanged');
								if (filteredMembers.length === 0) return '';

								const items = filteredMembers
									.sort((a, b) => a.value.localeCompare(b.value))
									.map(m => `<li class="${m.change}">${escapeHtml(m.value)}</li>`)
									.join('\\n');

								return `
									<details>
										<summary>Members</summary>
										<ul>
							${items}
										</ul>
									</details>
								`;
							}

							function renderNamedType(type) {
								const hasMembers = type.members && type.members.some(m => m.change !== 'unchanged');
								const hasTypes = type.named_types && type.named_types.some(t =>
									t.value.change !== 'unchanged' ||
									(t.members && t.members.some(m => m.change !== 'unchanged')) ||
									(t.named_types && t.named_types.length > 0) ||
									(t.conformance_changes && t.conformance_changes.length > 0) ||
									(t.attribute_changes && t.attribute_changes.length > 0)
								);
								const hasConformanceChanges = type.conformance_changes && type.conformance_changes.length > 0;
								const hasAttributeChanges = type.attribute_changes && type.attribute_changes.length > 0;

								if (!hasMembers && !hasTypes && !hasConformanceChanges && !hasAttributeChanges) return '';

								// Use pre-computed display name if available, otherwise escape the value
								const typeName = type.display_name || escapeHtml(type.value.value);

								// If this is a metadata-only change (only conformance/attribute changes, no members or nested types),
								// don't show a details element, just show the type name as a list item
								const isMetadataOnly = (hasConformanceChanges || hasAttributeChanges) && !hasMembers && !hasTypes;

								if (isMetadataOnly) {
									return `<div style="padding: 0.5em;">${typeName}</div>`;
								}

								return `
									<details>
										<summary>${typeName}</summary>
										${renderMembers(type.members)}
										${type.named_types ? type.named_types.map(renderNamedType).join('') : ''}
									</details>
								`;
							}

							function renderDependencies(dependencies) {
								if (!dependencies || dependencies.length === 0) return '';

								const filtered = dependencies.filter(d => d.change !== 'unchanged');
								if (filtered.length === 0) return '';

								const items = filtered
									.sort((a, b) => a.value.localeCompare(b.value))
									.map(d => `<li class="${d.change}">${escapeHtml(d.value)}</li>`)
									.join('\\n');

								return `
									<details>
										<summary>Dependencies</summary>
										<ul>
							${items}
										</ul>
									</details>
								`;
							}

							function renderPrecedenceGroups(groups) {
								if (!groups || groups.length === 0) return '';

								const filtered = groups.filter(g => g.change !== 'unchanged');
								if (filtered.length === 0) return '';

								const items = filtered
									.sort((a, b) => a.value.localeCompare(b.value))
									.map(g => `<li class="precedenceGroup">${escapeHtml(g.value)}</li>`)
									.join('\\n');

								return `
									<details>
										<summary>Precedence Groups</summary>
										<ul>
							${items}
										</ul>
									</details>
								`;
							}

							function renderFramework(framework) {
								const hasDeps = framework.dependencies && framework.dependencies.some(d => d.change !== 'unchanged');
								const hasMembers = framework.members && framework.members.some(m => m.change !== 'unchanged');
								const hasTypes = framework.named_types && framework.named_types.length > 0;
								const hasGroups = framework.precedence_groups && framework.precedence_groups.some(g => g.change !== 'unchanged');

								if (!hasDeps && !hasMembers && !hasTypes && !hasGroups) return '';

								const emoji = framework.value.change === 'added' ? '➕' : (framework.value.change === 'modified' ? '〰️' : '');

								return `
									<details>
										<summary>${emoji} <a href="https://developer.apple.com/documentation/${framework.value.value}">${escapeHtml(framework.value.value)}</a></summary>
										${renderDependencies(framework.dependencies)}
										${renderPrecedenceGroups(framework.precedence_groups)}
										${renderMembers(framework.members)}
										${hasTypes ? '<details><summary>Types</summary>' + framework.named_types.map(renderNamedType).join('') + '</details>' : ''}
									</details>
								`;
							}

							function renderArchitecture(architecture) {
								if (!architecture.frameworks || architecture.frameworks.length === 0) return '';

								const frameworks = architecture.frameworks.map(renderFramework).filter(Boolean).join('\\n');
								if (!frameworks) return '';

								return `
									<details>
										<summary>${escapeHtml(architecture.value.value)}</summary>
										${frameworks}
									</details>
								`;
							}

							function renderPlatform(platform, index) {
								if (!platform.architectures || platform.architectures.length === 0) return null;

								const architectures = platform.architectures.map(renderArchitecture).filter(Boolean).join('\\n');
								if (!architectures) return null;

								return {
									id: `platform_${index}`,
									name: platform.value.value,
									content: `
										<details open>
											<summary>${escapeHtml(platform.value.value)}</summary>
											${architectures}
										</details>
									`
								};
							}

							function render() {
								const platforms = data.map(renderPlatform).filter(Boolean);
								if (platforms.length === 0) {
									document.getElementById('app').innerHTML = '<p>No changes found.</p>';
									return;
								}

								const tabButtons = platforms.map((p, i) =>
									`<button class="tab-button ${i === 0 ? 'active' : ''}" data-tab="${p.id}">${escapeHtml(p.name)}</button>`
								).join('');

								const tabContents = platforms.map((p, i) =>
									`<div class="tab-content ${i === 0 ? 'active' : ''}" id="${p.id}">${p.content}</div>`
								).join('');

								document.getElementById('app').innerHTML = `
									<div class="tabs">
										<div class="tab-buttons">
											${tabButtons}
										</div>
										${tabContents}
									</div>
								`;

								// Add click handlers to tab buttons
								document.querySelectorAll('.tab-button').forEach(button => {
									button.addEventListener('click', () => {
										// Remove active class from all buttons and contents
										document.querySelectorAll('.tab-button').forEach(b => b.classList.remove('active'));
										document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));

										// Add active class to clicked button and corresponding content
										button.classList.add('active');
										const tabId = button.getAttribute('data-tab');
										document.getElementById(tabId).classList.add('active');
									});
								});
							}

							render();
							"""
						}
					}
				}

				let htmlPath = ("\(root)/swiftmodule-diff-\(fromVersion.name)-to-\(toVersion.name).dynamic.html" as NSString).expandingTildeInPath
				try! document.write(to: URL(fileURLWithPath: htmlPath), atomically: true, encoding: .utf8)
			}
		)
	}
}

// MARK: - HTML DSL

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
