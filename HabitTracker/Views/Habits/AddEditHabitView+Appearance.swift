import SwiftUI
import SwiftData

// Color and emoji pickers for AddEditHabitView.
extension AddEditHabitView {
    // MARK: - Color

    var presetColors: [HabitColor] {
        HabitColor.pickerColors
    }

    var currentDisplayColor: Color {
        selectedColor == .custom ? selectedCustomColor : selectedColor.color
    }

    /// Swatches shown inline in the form: nine presets plus a custom color, in two rows.
    var colorRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 12) {
            ForEach(presetColors, id: \.rawValue) { color in
                colorChip(color)
            }
            customColorChip
        }
        .padding(.vertical, 6)
    }

    func colorChip(_ color: HabitColor) -> some View {
        let isSelected = selectedColor == color
        return Button {
            withAnimation(.snappy(duration: 0.2)) { selectedColor = color }
        } label: {
            Circle()
                .fill(color.color)
                .frame(width: 32, height: 32)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(3)
                .overlay(Circle().strokeBorder(isSelected ? color.color : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityLabel(color.rawValue.capitalized)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    var customColorChip: some View {
        let isSelected = selectedColor == .custom
        return ColorPicker("Custom color", selection: Binding(
            get: { selectedCustomColor },
            set: { new in
                selectedCustomColor = new
                selectedColor = .custom
            }
        ))
        .labelsHidden()
        .frame(width: 32, height: 32)
        .padding(3)
        .overlay(Circle().strokeBorder(isSelected ? selectedCustomColor : .clear, lineWidth: 2))
    }

    // MARK: - Emoji

    /// Form row previewing the emoji on the habit's color.
    var emojiRow: some View {
        Button {
            Task { @MainActor in showingEmojiPickerSheet = true }
        } label: {
            HStack {
                Text("Emoji")
                Spacer()
                Text(resolvedEmoji)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(currentDisplayColor.opacity(0.18), in: Circle())
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var emojiPickerSheet: some View {
        #if os(macOS)
        emojiPickerContent
            .frame(minWidth: LayoutConfig.current.emojiPickerMinWidth, minHeight: LayoutConfig.current.emojiPickerMinHeight)
            .onAppear { anyEmojiText = "" }
        #else
        NavigationStack {
            emojiPickerContent
                .navigationTitle("Emoji")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear { anyEmojiText = "" }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingEmojiPickerSheet = false }
                    }
                }
        }
        #endif
    }

    private var typedEmoji: String? { HabitEmoji.firstEmoji(from: anyEmojiText) }

    private func pickEmoji(_ emoji: String?) {
        selectedEmoji = emoji
        showingEmojiPickerSheet = false
    }

    @ViewBuilder
    var emojiPickerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            #if os(macOS)
            HStack {
                Text("Choose emoji")
                    .font(.headline)
                Spacer()
                Button("Cancel") { showingEmojiPickerSheet = false }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
            Divider()
            #endif

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 10) {
                        Button {
                            pickEmoji(nil)
                        } label: {
                            Label {
                                Text("Suggested")
                            } icon: {
                                Text(suggestedEmoji)
                            }
                            .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.bordered)
                        .disabled(name.isEmpty)

                        TextField("Type any emoji", text: $anyEmojiText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { if let typedEmoji { pickEmoji(typedEmoji) } }
                        if let typedEmoji {
                            Button("Use \(typedEmoji)") { pickEmoji(typedEmoji) }
                                .buttonStyle(.borderedProminent)
                        }
                    }

                    ForEach(HabitEmoji.gridEmojis, id: \.category) { group in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(group.category)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 4)], spacing: 4) {
                                ForEach(group.emojis, id: \.self) { emoji in
                                    Button {
                                        pickEmoji(emoji)
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 28))
                                            .frame(width: 44, height: 44)
                                            .background(
                                                emoji == resolvedEmoji ? Color.brandPurple.opacity(0.2) : .clear,
                                                in: Circle()
                                            )
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}
