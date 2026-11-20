# Code style

Based on the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) and the [Google Swift Style Guide](https://google.github.io/swift/), trimmed for an app (not a library).

## Comments

**Default to no comment.** A good name and signature come first. Comment only what the code can't say: why, constraints, gotchas.

### Doc comments (`///`)

- Use `///` for documentation, `//` for everything else. No `/* */` or `/** */`.
- **Write one for:** every type, and any method or property used outside its file whose name doesn't fully explain it (services, models, shared helpers).
- **Skip for:** `body` and private view helpers, obvious enum cases, protocol conformances and overrides, test methods (name the test well instead), anything the name already says (`fetchHabits()`).
- **Summary first:** one sentence fragment ending with a period. Methods are verb phrases ("Merges duplicate habits..."), properties are noun phrases ("Habits due today, ..."). Never "This method...".
- **Details are optional:** after a blank `///` line, at most a short paragraph on why, invariants or pitfalls. Longer rationale goes in the commit message or `docs/`.
- `- Parameter` / `- Returns` / `- Throws` only when they add something the summary doesn't, in that order.

```swift
/// Merges habits that share a name, and same-day entries within each habit.
///
/// Duplicates come from sync. The surviving habit has the lowest id, so every device
/// makes the same choice.
@discardableResult
func mergeDuplicates() -> Int
```

### Inline comments (`//`)

- Explain why, not what. If it restates the line below it, delete it.
- Describe the code as it is now. History ("used to", "previously", "fixes X") belongs in commit messages.
- No commented-out code; git has it.
- `// TODO: <what> (<why or link>)` for known gaps. No bare TODOs.
- One space after `//`; end-of-line comments get two spaces before `//`.

### Structure

- `// MARK: - Section` to group files longer than about 100 lines.
- Full sentences with normal punctuation; US English.
