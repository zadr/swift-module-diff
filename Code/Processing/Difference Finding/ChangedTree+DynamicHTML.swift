import Foundation
import HTMLEntities

extension ChangedTree {
	static func dynamicHTMLVisitor(from fromVersion: Version, to toVersion: Version, root: String) -> ChangeVisitor {
		ChangeVisitor(
			didEnd: { tree in
				let title = "Xcode \(fromVersion.name) to Xcode \(toVersion.name) Diff"
				let description = "API changes between Xcode \(fromVersion.name) and Xcode \(toVersion.name)"

				// Extract all attributes from the FULL tree before filtering
				let allAttributes = Self.collectAllAttributes(from: tree)
				let allAttributesJSON = allAttributes.sorted().map { "\"\($0)\"" }.joined(separator: ",")

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

							.type-no-content {
								border: 1px solid #aaa;
								border-radius: 4px;
								padding: 0.5em;
								margin: 0.5em 0;
								font-weight: bold;
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

							.filter-control {
								margin: 20px 0;
								padding: 10px;
								background: #f5f5f5;
								border-radius: 4px;
								border: 1px solid #ccc;
							}

							.filter-control label {
								cursor: pointer;
								font-size: 14px;
							}

							.filter-control input[type="checkbox"] {
								margin-right: 8px;
								cursor: pointer;
							}

							.filter-control label {
								display: inline-block;
								margin-right: 15px;
							}

							/* Custom dropdown for attribute filtering */
							.attr-dropdown {
								position: relative;
								display: inline-block;
								margin-left: 20px;
							}

							.attr-dropdown-button {
								background: white;
								border: 1px solid #ccc;
								padding: 5px 30px 5px 10px;
								cursor: pointer;
								border-radius: 3px;
								font-size: 14px;
								position: relative;
							}

							.attr-dropdown-button:hover {
								background: #f9f9f9;
							}

							.attr-dropdown-button .dropdown-arrow {
								position: absolute;
								right: 8px;
								top: 50%;
								transform: translateY(-50%);
								font-size: 10px;
								transition: transform 0.2s ease;
							}

							.attr-dropdown-button.open .dropdown-arrow {
								transform: translateY(-50%) rotate(180deg);
							}

							.attr-dropdown-menu {
								display: none;
								position: absolute;
								top: 100%;
								left: 0;
								background: white;
								border: 1px solid #ccc;
								border-radius: 3px;
								box-shadow: 0 2px 8px rgba(0,0,0,0.15);
								min-width: 200px;
								max-height: 400px;
								overflow-y: auto;
								z-index: 1000;
								margin-top: 2px;
							}

							.attr-dropdown-menu.show {
								display: block;
							}

							.attr-dropdown-item {
								padding: 0;
								cursor: pointer;
								border-bottom: 1px solid #f0f0f0;
								display: block;
								font-size: 14px;
								margin: 0;
							}

							.attr-dropdown-item:last-child {
								border-bottom: none;
							}

							.attr-dropdown-item:hover {
								background: #f5f5f5;
							}

							.attr-dropdown-item label {
								display: flex;
								align-items: center;
								padding: 8px 12px;
								cursor: pointer;
								margin: 0;
								width: 100%;
								box-sizing: border-box;
							}

							.attr-dropdown-item input[type="checkbox"] {
								margin-right: 8px;
								cursor: pointer;
								flex-shrink: 0;
							}

							.attr-dropdown-item span {
								flex: 1;
								white-space: nowrap;
								overflow: hidden;
								text-overflow: ellipsis;
							}

							/* Hide filtered members when filtering is enabled */
							body.filtering-enabled .platform-filtered {
								display: none !important;
							}

							"""
						}
					}
					body {
						div(id: "app") { "Loading..." }
						script {
							"""
							const data = JSON.parse(`\(escapedJSON)`);

							// Initialize filtering as enabled
							document.body.classList.add('filtering-enabled');

							// All attributes from the full tree (before filtering)
							const allAttributes = new Set([\(allAttributesJSON)]);
							let hiddenAttributes = new Set();

							function escapeHtml(text) {
								const div = document.createElement('div');
								div.textContent = text;
								return div.innerHTML;
							}

							// Extract all @ attributes from a declaration
							function extractAttributes(declaration) {
								const attrs = new Set();
								// Match @ followed by identifier
								const regex = /@([a-zA-Z_][a-zA-Z0-9_]*)/g;
								let match;
								while ((match = regex.exec(declaration)) !== null) {
									attrs.add('@' + match[1]);
								}
								return Array.from(attrs);
							}

							// Extract ALL @available attributes from a declaration
							// Returns array of {platform, full, isUnavailable} where:
							//   - platform is the platform name
							//   - full is the complete @available text
							//   - isUnavailable indicates if it's marked as "unavailable"
							function extractAllAvailableAttributes(declaration) {
								const availables = [];
								const regex = /@available\\s*\\([^)]+\\)/g;
								let match;
								while ((match = regex.exec(declaration)) !== null) {
									const fullAttr = match[0];

									// Check if this is a multi-platform @available like:
									// @available(iOS: 16.0, macOS: 13.0, tvOS: 16.0, *)
									const multiPlatformRegex = /([a-zA-Z]+)\\s*:/g;
									const platformMatches = [];
									let platformMatch;
									while ((platformMatch = multiPlatformRegex.exec(fullAttr)) !== null) {
										platformMatches.push(platformMatch[1]);
									}

									if (platformMatches.length > 0) {
										// Multi-platform format - add each platform separately
										platformMatches.forEach(platform => {
											availables.push({
												platform: platform,
												full: fullAttr,
												isUnavailable: fullAttr.includes('unavailable')
											});
										});
									} else {
										// Single platform format like @available(iOS 14.0, *) or @available(macOS, unavailable)
										const singlePlatformMatch = fullAttr.match(/@available\\s*\\(\\s*([a-zA-Z]+)/);
										if (singlePlatformMatch) {
											availables.push({
												platform: singlePlatformMatch[1],
												full: fullAttr,
												isUnavailable: fullAttr.includes('unavailable')
											});
										}
									}
								}
								return availables;
							}

							// Normalize platform name for matching
							// Maps platform variants to their base platform for tab matching
							function normalizePlatformName(platformName) {
								if (!platformName) return null;
								const lower = platformName.toLowerCase();

								// Handle ApplicationExtension variants - strip suffix and return base platform
								if (lower.endsWith('applicationextension')) {
									const base = platformName.substring(0, platformName.length - 'applicationextension'.length);
									return normalizePlatformName(base);
								}

								// Handle OSX as macOS
								if (lower === 'osx') return 'macOS';

								// Handle macCatalyst - show on both iOS and macOS tabs
								if (lower === 'maccatalyst') return 'macCatalyst';

								// Handle driverKit - show on macOS tab
								if (lower === 'driverkit') return 'macOS';

								// Return standardized capitalization
								if (lower === 'ios') return 'iOS';
								if (lower === 'macos') return 'macOS';
								if (lower === 'tvos') return 'tvOS';
								if (lower === 'watchos') return 'watchOS';
								if (lower === 'visionos') return 'visionOS';

								return platformName;
							}

							// Check if platform matches for display
							function platformMatches(availablePlatform, currentPlatform) {
								const normalized = normalizePlatformName(availablePlatform);
								const currentNormalized = normalizePlatformName(currentPlatform);

								// macCatalyst shows on both iOS and macOS tabs
								if (normalized === 'macCatalyst') {
									return currentNormalized === 'iOS' || currentNormalized === 'macOS';
								}

								return normalized === currentNormalized;
							}

							// Analyze a member's platform availability
							// Returns object with:
							//   - availablePlatforms: array of platforms to show this on
							//   - filteredTexts: object mapping platform -> filtered text for that platform
							function analyzeMemberAvailability(memberDeclaration) {
								const availables = extractAllAvailableAttributes(memberDeclaration);

								// If no @available attributes, show on all platforms as-is
								if (availables.length === 0) {
									return {
										availablePlatforms: ['iOS', 'macOS', 'tvOS', 'watchOS', 'visionOS'],
										filteredTexts: {},
										originalText: memberDeclaration
									};
								}

								const filteredTexts = {};
								const allPlatforms = ['iOS', 'macOS', 'tvOS', 'watchOS', 'visionOS'];

								// Determine which platforms this member is available on
								const explicitlyAvailableOn = new Set();
								const explicitlyUnavailableOn = new Set();

								availables.forEach(attr => {
									const normalized = normalizePlatformName(attr.platform);

									if (attr.isUnavailable) {
										// Mark as unavailable - only for the specific platform
										// Don't expand macCatalyst to iOS/macOS for unavailable
										explicitlyUnavailableOn.add(normalized);
									} else {
										// Mark as available
										if (normalized === 'macCatalyst') {
											// macCatalyst available means available on both iOS and macOS
											explicitlyAvailableOn.add('iOS');
											explicitlyAvailableOn.add('macOS');
										} else {
											explicitlyAvailableOn.add(normalized);
										}
									}
								});

								// Build list of available platforms
								// A platform is available if:
								// - It's explicitly mentioned as available, OR
								// - It's not explicitly mentioned at all (implicitly available)
								// AND it's not explicitly marked unavailable
								const availablePlatforms = allPlatforms.filter(p => {
									// If explicitly unavailable, exclude it
									if (explicitlyUnavailableOn.has(p)) {
										return false;
									}
									// If we have any explicit availability declarations and this platform isn't mentioned, exclude it
									if (explicitlyAvailableOn.size > 0 && !explicitlyAvailableOn.has(p)) {
										return false;
									}
									// Otherwise include it
									return true;
								});

								// Group availables by their 'full' attribute text (same @available declaration)
								const availablesByFull = {};
								availables.forEach(attr => {
									if (!availablesByFull[attr.full]) {
										availablesByFull[attr.full] = [];
									}
									availablesByFull[attr.full].push(attr);
								});

								// Check each platform
								allPlatforms.forEach(platform => {
									// Generate filtered text for this platform
									let filtered = memberDeclaration;

									// Process each unique @available declaration
									Object.keys(availablesByFull).forEach(fullAttr => {
										const attrs = availablesByFull[fullAttr];

										// Check if ANY platform in this @available matches current platform
										const hasMatchingPlatform = attrs.some(attr =>
											platformMatches(attr.platform, platform)
										);

										// Check if this @available has wildcard - if so, it's relevant to all platforms
										const hasWildcardInThis = fullAttr.includes('*');

										// Remove if no platforms in this @available match AND no wildcard
										if (!hasMatchingPlatform && !hasWildcardInThis) {
											filtered = filtered.replace(fullAttr + ' ', '');
											filtered = filtered.replace(fullAttr, '');
										}
									});

									filteredTexts[platform] = filtered.trim();
								});

								return {
									availablePlatforms,
									filteredTexts,
									originalText: memberDeclaration
								};
							}

							function renderMembers(members, currentPlatform) {
								if (!members || members.length === 0) return '';

								const processedMembers = members
									.filter(m => m.change !== 'unchanged')
									.map(m => {
										const analysis = analyzeMemberAvailability(m.value);
										return { ...m, analysis };
									});

								if (processedMembers.length === 0) return '';

								const items = processedMembers
									.sort((a, b) => a.analysis.originalText.localeCompare(b.analysis.originalText))
									.map(m => {
										const platforms = m.analysis.availablePlatforms;
										const isAvailableOnCurrent = platforms.includes(currentPlatform);

										// Extract all attributes (including @available) for filtering
										const attrs = extractAttributes(m.analysis.originalText);

										// Add class to hide when filtering is enabled and not available on this platform
										const filterClass = isAvailableOnCurrent ? '' : ' platform-filtered';

										// Use filtered text for current platform if available, otherwise original
										const displayText = m.analysis.filteredTexts[currentPlatform] || m.analysis.originalText;

										const attrsData = attrs.length > 0 ? ' data-attrs="' + attrs.join(',') + '"' : '';

										return '<li class="' + m.change + filterClass + '" data-platforms="' + platforms.join(',') + '"' + attrsData + ' data-original="' + escapeHtml(m.analysis.originalText).replace(/"/g, '&quot;') + '" data-filtered="' + escapeHtml(displayText).replace(/"/g, '&quot;') + '">' +
											'<span class="member-text-filtered">' + escapeHtml(displayText) + '</span>' +
											'<span class="member-text-unfiltered" style="display:none">' + escapeHtml(m.analysis.originalText) + '</span>' +
										'</li>';
									})
									.join('\\n');

								return '<details>' +
										'<summary>Members</summary>' +
										'<ul>' +
							items +
										'</ul>' +
									'</details>';
							}

							function renderNamedType(type, currentPlatform) {
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
								const typeChanged = type.value.change !== 'unchanged';

								// Get the type name (from display_name if available, otherwise from value)
								const rawTypeName = type.display_name || type.value.value;

								// Extract all attributes (including @available) for filtering
								const attrs = extractAttributes(rawTypeName);

								// Analyze availability and create filtered/unfiltered versions
								const analysis = analyzeMemberAvailability(rawTypeName);
								const platforms = analysis.availablePlatforms;
								const isAvailableOnCurrent = platforms.includes(currentPlatform);
								const filterClass = isAvailableOnCurrent ? '' : ' platform-filtered';
								const filteredTypeName = analysis.filteredTexts[currentPlatform] || rawTypeName;

								const attrsData = attrs.length > 0 ? ' data-attrs="' + attrs.join(',') + '"' : '';
								const dataAttrs = ' data-platforms="' + platforms.join(',') + '"' + attrsData +
									' data-original="' + escapeHtml(rawTypeName).replace(/"/g, '&quot;') +
									'" data-filtered="' + escapeHtml(filteredTypeName).replace(/"/g, '&quot;') + '"';

								// Create the dual display spans
								const typeNameDisplay = `
									<span class="member-text-filtered">${type.display_name ? filteredTypeName : escapeHtml(filteredTypeName)}</span>
									<span class="member-text-unfiltered" style="display:none">${type.display_name ? rawTypeName : escapeHtml(rawTypeName)}</span>
								`;

								// If the type itself changed (added/removed) but has no content, show it styled like details but not expandable
								if (typeChanged && !hasMembers && !hasTypes && !hasConformanceChanges && !hasAttributeChanges) {
									return '<div class="' + filterClass + ' type-no-content"' + dataAttrs + '>' + typeNameDisplay + '</div>';
								}

								// If nothing changed at all, don't show it
								if (!hasMembers && !hasTypes && !hasConformanceChanges && !hasAttributeChanges) return '';

								// If this is a metadata-only change (only conformance/attribute changes, no members or nested types),
								// show it styled like details but not expandable
								const isMetadataOnly = (hasConformanceChanges || hasAttributeChanges) && !hasMembers && !hasTypes;

								if (isMetadataOnly) {
									return '<div class="' + filterClass + ' type-no-content"' + dataAttrs + '>' + typeNameDisplay + '</div>';
								}

								return '<details class="' + filterClass + '"' + dataAttrs + '>' +
										'<summary>' + typeNameDisplay + '</summary>' +
										renderMembers(type.members, currentPlatform) +
										(type.named_types ? type.named_types.map(t => renderNamedType(t, currentPlatform)).join('') : '') +
									'</details>';
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

							function renderFramework(framework, currentPlatform) {
								const hasDeps = framework.dependencies && framework.dependencies.some(d => d.change !== 'unchanged');
								const hasMembers = framework.members && framework.members.some(m => m.change !== 'unchanged');
								const hasTypes = framework.named_types && framework.named_types.length > 0;
								const hasGroups = framework.precedence_groups && framework.precedence_groups.some(g => g.change !== 'unchanged');

								if (!hasDeps && !hasMembers && !hasTypes && !hasGroups) return '';

								const emoji = framework.value.change === 'added' ? '➕' : (framework.value.change === 'modified' ? '〰️' : '');

								// Render types and only show if there's actual content
								const renderedTypes = hasTypes ? framework.named_types.map(t => renderNamedType(t, currentPlatform)).join('') : '';
								const typesSection = renderedTypes ? '<details><summary>Types</summary>' + renderedTypes + '</details>' : '';

								return `
									<details>
										<summary>${emoji} <a href="https://developer.apple.com/documentation/${framework.value.value}">${escapeHtml(framework.value.value)}</a></summary>
										${renderDependencies(framework.dependencies)}
										${renderPrecedenceGroups(framework.precedence_groups)}
										${renderMembers(framework.members, currentPlatform)}
										${typesSection}
									</details>
								`;
							}

							function renderArchitecture(architecture, currentPlatform) {
								if (!architecture.frameworks || architecture.frameworks.length === 0) return '';

								const frameworks = architecture.frameworks.map(f => renderFramework(f, currentPlatform)).filter(Boolean).join('\\n');
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

								const currentPlatform = platform.value.value;
								const architectures = platform.architectures.map(a => renderArchitecture(a, currentPlatform)).filter(Boolean).join('\\n');
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

							// Helper to skip balanced parentheses in attribute arguments
							function skipBalancedParens(str, startIdx) {
								let depth = 1;
								let i = startIdx;
								while (i < str.length && depth > 0) {
									if (str[i] === '(') depth++;
									else if (str[i] === ')') depth--;
									i++;
								}
								return i;
							}

							// Remove a specific attribute from text, handling nested parens
							function removeAttribute(text, attrName) {
								let result = text;
								const attrPattern = '@' + attrName;

								while (true) {
									const idx = result.indexOf(attrPattern);
									if (idx === -1) break;

									let endIdx = idx + attrPattern.length;

									// Check if followed by parentheses
									if (endIdx < result.length && result[endIdx] === '(') {
										endIdx = skipBalancedParens(result, endIdx + 1);
									}

									// Skip trailing whitespace
									while (endIdx < result.length && /\\s/.test(result[endIdx])) {
										endIdx++;
									}

									result = result.slice(0, idx) + result.slice(endIdx);
								}

								return result;
							}

							function updateAttributeFiltering() {
								console.log('updateAttributeFiltering called, hiddenAttributes:', hiddenAttributes);
								// Apply attribute filtering by stripping hidden attributes from text
								document.querySelectorAll('[data-attrs]').forEach(el => {
									const originalText = el.getAttribute('data-original');
									const platformFilteredText = el.getAttribute('data-filtered');
									if (!originalText) return;

									const attrs = el.getAttribute('data-attrs').split(',').filter(a => a);

									// If no attributes are hidden, restore original texts
									if (hiddenAttributes.size === 0) {
										const filteredSpan = el.querySelector('.member-text-filtered');
										const unfilteredSpan = el.querySelector('.member-text-unfiltered');
										if (filteredSpan) filteredSpan.textContent = platformFilteredText || originalText;
										if (unfilteredSpan) unfilteredSpan.textContent = originalText;
										return;
									}

									// Remove hidden attributes from both the platform-filtered and original text
									let attrFilteredOriginal = originalText;
									let attrFilteredPlatform = platformFilteredText || originalText;

									attrs.forEach(attr => {
										if (hiddenAttributes.has(attr)) {
											attrFilteredOriginal = removeAttribute(attrFilteredOriginal, attr);
											attrFilteredPlatform = removeAttribute(attrFilteredPlatform, attr);
										}
									});

									// Update both spans
									const filteredSpan = el.querySelector('.member-text-filtered');
									const unfilteredSpan = el.querySelector('.member-text-unfiltered');
									if (filteredSpan) filteredSpan.textContent = attrFilteredPlatform.trim();
									if (unfilteredSpan) unfilteredSpan.textContent = attrFilteredOriginal.trim();
								});
							}

							function render() {
								const platforms = data.map(renderPlatform).filter(Boolean);
								if (platforms.length === 0) {
									document.getElementById('app').innerHTML = '<p>No changes found.</p>';
									return;
								}

								// Build attribute filter dropdown
								const sortedAttrs = Array.from(allAttributes).sort();

								// Build custom dropdown with checkboxes
								const attrDropdown = sortedAttrs.length > 0 ?
									'<div class="attr-dropdown">' +
										'<div class="attr-dropdown-button" id="attrDropdownBtn">' +
											'<span id="attrDropdownLabel">Hide attributes</span>' +
											'<span class="dropdown-arrow">▼</span>' +
										'</div>' +
										'<div class="attr-dropdown-menu" id="attrDropdownMenu">' +
											sortedAttrs.map(attr =>
												'<div class="attr-dropdown-item">' +
													'<label>' +
														'<input type="checkbox" class="attr-checkbox" value="' + escapeHtml(attr) + '">' +
														'<span>' + escapeHtml(attr) + '</span>' +
													'</label>' +
												'</div>'
											).join('') +
										'</div>' +
									'</div>' :
									'';

								const tabButtons = platforms.map((p, i) =>
									'<button class="tab-button ' + (i === 0 ? 'active' : '') + '" data-tab="' + p.id + '">' + escapeHtml(p.name) + '</button>'
								).join('');

								const tabContents = platforms.map((p, i) =>
									'<div class="tab-content ' + (i === 0 ? 'active' : '') + '" id="' + p.id + '">' + p.content + '</div>'
								).join('');

								document.getElementById('app').innerHTML =
									'<div class="filter-control">' +
										'<label>' +
											'<input type="checkbox" id="availableFilter" checked>' +
											'@available filtering' +
										'</label>' +
										attrDropdown +
									'</div>' +
									'<div class="tabs">' +
										'<div class="tab-buttons">' +
											tabButtons +
										'</div>' +
										tabContents +
									'</div>';

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

								// Add change handler to checkbox
								const checkbox = document.getElementById('availableFilter');
								if (checkbox) {
									checkbox.addEventListener('change', () => {
										if (checkbox.checked) {
											// Enable filtering
											document.body.classList.add('filtering-enabled');
											// Show filtered text, hide unfiltered
											document.querySelectorAll('.member-text-filtered').forEach(el => el.style.display = '');
											document.querySelectorAll('.member-text-unfiltered').forEach(el => el.style.display = 'none');
										} else {
											// Disable filtering
											document.body.classList.remove('filtering-enabled');
											// Show unfiltered text, hide filtered
											document.querySelectorAll('.member-text-filtered').forEach(el => el.style.display = 'none');
											document.querySelectorAll('.member-text-unfiltered').forEach(el => el.style.display = '');
										}
									});
								}

								// Add dropdown toggle handler
								const dropdownBtn = document.getElementById('attrDropdownBtn');
								const dropdownMenu = document.getElementById('attrDropdownMenu');
								if (dropdownBtn && dropdownMenu) {
									// Toggle dropdown on button click
									dropdownBtn.addEventListener('click', (e) => {
										e.stopPropagation();
										const isOpen = dropdownMenu.style.display === 'block';
										dropdownMenu.style.display = isOpen ? 'none' : 'block';
										dropdownBtn.classList.toggle('open', !isOpen);
									});

									// Close dropdown when clicking outside
									document.addEventListener('click', (e) => {
										if (!e.target.closest('.attr-dropdown')) {
											dropdownMenu.style.display = 'none';
											dropdownBtn.classList.remove('open');
										}
									});

									// Handle checkbox changes
									const checkboxes = dropdownMenu.querySelectorAll('.attr-checkbox');
									checkboxes.forEach(checkbox => {
										checkbox.addEventListener('change', () => {
											// Update hiddenAttributes set based on checkbox states
											hiddenAttributes.clear();
											checkboxes.forEach(cb => {
												if (cb.checked) {
													hiddenAttributes.add(cb.value);
												}
											});

											// Update dropdown label to show count
											const count = hiddenAttributes.size;
											const label = document.getElementById('attrDropdownLabel');
											if (label) {
												label.textContent = count > 0 ? `Hide attributes (${count} selected)` : 'Hide attributes';
											}

											updateAttributeFiltering();
										});
									});
								}
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

// MARK: - Attribute Collection

extension ChangedTree {
	/// Collect all unique attributes from the entire tree (before filtering)
	static func collectAllAttributes(from tree: StorageTree) -> Set<String> {
		var attributes = Set<String>()
		let regex = try! NSRegularExpression(pattern: "@([a-zA-Z_][a-zA-Z0-9_]*)", options: [])

		func extractAttributes(from text: String) {
			let range = NSRange(text.startIndex..<text.endIndex, in: text)
			regex.enumerateMatches(in: text, range: range) { match, _, _ in
				guard let match = match, match.numberOfRanges > 1 else { return }
				let attrRange = match.range(at: 1)
				if let swiftRange = Range(attrRange, in: text) {
					attributes.insert("@" + String(text[swiftRange]))
				}
			}
		}

		func extractFromChange<T>(_ change: Change<T>, _ extract: (T) -> String) {
			switch change {
			case .removed(let old, let new), .modified(let old, let new),
			     .unchanged(let old, let new), .added(let old, let new):
				extractAttributes(from: extract(old))
				extractAttributes(from: extract(new))
			}
		}

		// Walk through all platforms
		for platform in tree {
			// Walk through all architectures
			for architecture in platform.architectures {
				// Walk through all frameworks
				for framework in architecture.frameworks {
					// Collect from framework members
					for member in framework.members {
						extractFromChange(member) { $0 }
					}

					// Walk through named types
					func processNamedType(_ namedType: ChangedTree.Platform.Architecture.Framework.NamedType) {
						// Get type declaration
						if let displayName = namedType.displayName {
							extractAttributes(from: displayName)
						}
						extractFromChange(namedType.value) { $0 }

						// Collect from members
						for member in namedType.members {
							extractFromChange(member) { $0 }
						}

						// Collect from attribute changes
						for attrChange in namedType.attributeChanges {
							extractFromChange(attrChange) { $0 }
						}

						// Recursively process nested types
						for nested in namedType.namedTypes {
							processNamedType(nested)
						}
					}

					for namedType in framework.namedTypes {
						processNamedType(namedType)
					}

					// Collect from dependencies
					for dependency in framework.dependencies {
						extractFromChange(dependency) { $0 }
					}
				}
			}
		}

		return attributes
	}
}
