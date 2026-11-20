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

    @ViewBuilder
    var colorRow: some View {
        Button {
            Task { @MainActor in showingColorPickerSheet = true }
        } label: {
            HStack {
                Text("Color")
                Spacer()
                Circle()
                    .fill(currentDisplayColor)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .strokeBorder(.secondary.opacity(0.5), lineWidth: 1)
                    )
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var colorPickerSheet: some View {
        #if os(macOS)
        let config = LayoutConfig.current
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Choose color")
                    .font(.headline)
                Spacer()
                Button("Done") { showingColorPickerSheet = false }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, config.sheetHeaderPaddingHorizontal)
            .padding(.top, config.sheetHeaderPaddingTop)
            .padding(.bottom, config.sheetHeaderPaddingBottom)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: config.spacingL) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: config.emojiGridSpacing), count: config.colorGridColumns), spacing: config.emojiGridSpacing) {
                        ForEach(presetColors, id: \.rawValue) { color in
                            colorChip(color)
                        }
                        customColorChip
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: config.colorPickerMinWidth, minHeight: config.colorPickerMinHeight)
        #else
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: LayoutConfig.current.spacingL) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConfig.current.emojiGridSpacing), count: LayoutConfig.current.colorGridColumns), spacing: LayoutConfig.current.emojiGridSpacing) {
                        ForEach(presetColors, id: \.rawValue) { color in
                            colorChip(color)
                        }
                        customColorChip
                    }
                }
                .padding()
            }
            .navigationTitle("Choose color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showingColorPickerSheet = false }
                }
            }
        }
        .navigationViewStyle(.stack)
        #endif
    }

    func colorChip(_ color: HabitColor) -> some View {
        let isSelected = selectedColor == color
        return Button {
            selectedColor = color
        } label: {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: LayoutConfig.current.colorChipSize, height: LayoutConfig.current.colorChipSize)
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 2.5)
                        .frame(width: LayoutConfig.current.colorChipSize, height: LayoutConfig.current.colorChipSize)
                    Circle()
                        .strokeBorder(color.color.opacity(0.6), lineWidth: 1)
                        .frame(width: LayoutConfig.current.colorChipSize + 4, height: LayoutConfig.current.colorChipSize + 4)
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 0, x: 0, y: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    var customColorChip: some View {
        let isSelected = selectedColor == .custom
        return ZStack {
            ColorPicker("", selection: Binding(
                get: { selectedCustomColor },
                set: { new in
                    selectedCustomColor = new
                    selectedColor = .custom
                }
            ))
            .labelsHidden()
            .frame(width: LayoutConfig.current.colorChipSize, height: LayoutConfig.current.colorChipSize)
            .opacity(isSelected ? 1 : 0.6)
            if isSelected {
                Circle()
                    .strokeBorder(.white, lineWidth: 2.5)
                    .frame(width: LayoutConfig.current.colorChipSize, height: LayoutConfig.current.colorChipSize)
                Circle()
                    .strokeBorder(selectedCustomColor.opacity(0.8), lineWidth: 1)
                    .frame(width: LayoutConfig.current.colorChipSize + 4, height: LayoutConfig.current.colorChipSize + 4)
            }
        }
    }

    @ViewBuilder
    var emojiRow: some View {
        Button {
            Task { @MainActor in showingEmojiPickerSheet = true }
        } label: {
            HStack {
                Text("Emoji")
                Spacer()
                Text(resolvedEmoji)
                    .font(.title2)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
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
        NavigationView {
            emojiPickerContent
                .navigationTitle("Choose emoji")
                .onAppear { anyEmojiText = "" }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingEmojiPickerSheet = false }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        #endif
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
            .padding(.horizontal, LayoutConfig.current.sheetHeaderPaddingHorizontal)
            .padding(.top, LayoutConfig.current.sheetHeaderPaddingTop)
            .padding(.bottom, LayoutConfig.current.sheetHeaderPaddingBottom)
            Divider()
            #endif

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 0) {
                        Button {
                            selectedEmoji = nil
                            showingEmojiPickerSheet = false
                        } label: {
                            HStack(spacing: 10) {
                                Text(suggestedEmoji)
                                    .font(.title2)
                                Text("Suggested")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        .disabled(name.isEmpty)

                        Rectangle()
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: 1)
                            .padding(.vertical, 8)

                        HStack(spacing: 10) {
                            TextField("Any emoji", text: $anyEmojiText)
                                .textFieldStyle(.plain)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                            Button {
                                if let emoji = HabitEmoji.firstEmoji(from: anyEmojiText) {
                                    selectedEmoji = emoji
                                    showingEmojiPickerSheet = false
                                }
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(HabitEmoji.firstEmoji(from: anyEmojiText) != nil ? Color.accentColor : Color.secondary.opacity(0.4))
                            }
                            .disabled(HabitEmoji.firstEmoji(from: anyEmojiText) == nil)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                    }
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                    )

                    ForEach(HabitEmoji.gridEmojis, id: \.category) { group in
                        VStack(alignment: .leading, spacing: LayoutConfig.current.spacingS) {
                            Text(group.category)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConfig.current.emojiGridSpacing), count: LayoutConfig.current.emojiGridColumns), spacing: LayoutConfig.current.emojiGridSpacing) {
                                ForEach(group.emojis, id: \.self) { emoji in
                                    Button {
                                        selectedEmoji = emoji
                                        showingEmojiPickerSheet = false
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: LayoutConfig.current.emojiCellSize - 16))
                                            .frame(width: LayoutConfig.current.emojiCellSize, height: LayoutConfig.current.emojiCellSize)
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
