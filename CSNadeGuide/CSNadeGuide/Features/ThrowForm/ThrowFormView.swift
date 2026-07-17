import SwiftUI
import SwiftData
import PhotosUI

/// Screen 4: the create/edit form. Title, map/side/type selectors, technique
/// controls, callout fields with autocomplete, three image slots that route
/// through PhotosPicker into the crop/aim editor, and notes. Save writes
/// SwiftData and stamps `updatedAt`.
struct ThrowFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// nil → create a new throw; non-nil → edit that throw in place.
    let existing: Throw?

    @State private var title: String
    @State private var map: GameMap
    @State private var side: Side
    @State private var type: NadeType
    @State private var power: ThrowPower
    @State private var movement: ThrowMovement
    @State private var isBounce: Bool
    @State private var standCallout: String
    @State private var targetCallout: String
    @State private var notes: String
    @State private var drafts: [ImageRole: SlotDraft]

    // Picker/editor routing. `pickerRole` is deliberately NOT tied to the
    // picker's presentation: PhotosPicker dismisses itself before the async
    // selection arrives, so presentation state and "which slot is waiting"
    // must be separate or the picked photo gets dropped.
    @State private var pickerRole: ImageRole?
    @State private var isPickerPresented = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var editorRole: ImageRole?
    /// Slot state before a pick/replace, restored if the editor is cancelled.
    @State private var editorPreviousDraft: SlotDraft?
    @State private var editorIsFreshPick = false
    @State private var importFailed = false
    @State private var didSave = false
    @FocusState private var focusedField: Field?

    private enum Field { case title, standCallout, targetCallout, notes }

    /// Working copy of one image slot. `isNewData` marks bytes that must be
    /// (re)written on save, so unchanged images aren't rewritten to disk.
    struct SlotDraft {
        var data: Data
        var image: UIImage
        var cropRect: NormalizedRect = .full
        var aimPoint: NormalizedPoint?
        var isNewData = true
    }

    init(existing: Throw? = nil) {
        self.existing = existing
        _title = State(initialValue: existing?.title ?? "")
        _map = State(initialValue: existing?.map ?? .mirage)
        _side = State(initialValue: existing?.side ?? .t)
        _type = State(initialValue: existing?.type ?? .smoke)
        _power = State(initialValue: existing?.power ?? .left)
        _movement = State(initialValue: existing?.movement ?? .standing)
        _isBounce = State(initialValue: existing?.isBounce ?? false)
        _standCallout = State(initialValue: existing?.standCallout ?? "")
        _targetCallout = State(initialValue: existing?.targetCallout ?? "")
        _notes = State(initialValue: existing?.notes ?? "")

        var slots: [ImageRole: SlotDraft] = [:]
        for role in ImageRole.allCases {
            if let stored = existing?.image(for: role),
               let data = stored.imageData,
               let ui = UIImage(data: data) {
                slots[role] = SlotDraft(
                    data: data,
                    image: ui,
                    cropRect: stored.cropRect,
                    aimPoint: stored.aimPoint,
                    isNewData: false
                )
            }
        }
        _drafts = State(initialValue: slots)
    }

    /// Creation requires at least one image; editing doesn't — imageless
    /// throws legitimately exist (the textbook seeds) and must stay editable.
    private var canSave: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespaces).isEmpty
        return hasTitle && (existing != nil || !drafts.isEmpty)
    }

    /// Anything worth protecting from an accidental swipe-down.
    private var blocksInteractiveDismiss: Bool {
        !title.isEmpty || !drafts.isEmpty || !notes.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            navRow
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    titleField
                    section("MAP") { mapGrid }
                    sideTypeRow
                    section("TECHNIQUE") { techniqueControls }
                    section("CALLOUTS") { calloutFields }
                    section("IMAGES") { imageSlots }
                    section("NOTES") { notesField }
                }
                .padding(.horizontal, Theme.margin)
                .padding(.top, 14)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.bg.ignoresSafeArea())
        .interactiveDismissDisabled(blocksInteractiveDismiss)
        .photosPicker(isPresented: $isPickerPresented, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            let role = pickerRole
            Task {
                if let role,
                   let raw = try? await item.loadTransferable(type: Data.self),
                   let processed = ImageImportPipeline.process(data: raw),
                   let ui = UIImage(data: processed) {
                    editorPreviousDraft = drafts[role]
                    editorIsFreshPick = true
                    drafts[role] = SlotDraft(data: processed, image: ui)
                    editorRole = role
                } else {
                    importFailed = true
                }
                pickerItem = nil
                pickerRole = nil
            }
        }
        .fullScreenCover(item: $editorRole) { role in
            if let draft = drafts[role] {
                CropAimEditorScreen(
                    image: draft.image,
                    cropRect: draft.cropRect,
                    aimPoint: draft.aimPoint,
                    allowsAim: role == .aim
                ) { rect, point in
                    drafts[role]?.cropRect = rect
                    drafts[role]?.aimPoint = point
                    editorIsFreshPick = false
                } onCancel: {
                    // Cancelling the editor right after a pick/replace also
                    // cancels the pick itself.
                    if editorIsFreshPick {
                        drafts[role] = editorPreviousDraft
                        editorIsFreshPick = false
                    }
                }
            }
        }
        .alert("Couldn't import that image", isPresented: $importFailed) {
            Button("OK") {}
        } message: {
            Text("The selected photo couldn't be loaded. Try a different screenshot.")
        }
    }

    // MARK: Nav row

    private var navRow: some View {
        ZStack {
            Text(existing == nil ? "New Throw" : "Edit Throw")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            HStack {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                Spacer()
                Button("Save") { save() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canSave ? Theme.accent : Theme.textTertiary)
                    .disabled(!canSave)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.margin)
        .padding(.vertical, 12)
    }

    // MARK: Sections

    private func section(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Theme.mono(10))
                .tracking(1)
                .foregroundStyle(Theme.textSecondary)
            content()
        }
    }

    private var titleField: some View {
        TextField(
            "",
            text: $title,
            prompt: Text("Throw title").foregroundStyle(Theme.textSecondary)
        )
        .font(.system(size: 16))
        .foregroundStyle(Theme.textPrimary)
        .focused($focusedField, equals: .title)
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusControl))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusControl)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var mapGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Theme.gapSmall), count: 5),
            spacing: Theme.gapSmall
        ) {
            ForEach(orderedMaps) { candidate in
                selectorCell(
                    isSelected: map == candidate,
                    height: 34
                ) {
                    Text(candidate.code)
                        .font(Theme.mono(11, weight: map == candidate ? .semibold : .regular))
                        .foregroundStyle(
                            map == candidate
                                ? Theme.accent
                                : (candidate.isActiveDuty ? Theme.textSecondary : Theme.textTertiary)
                        )
                } action: {
                    map = candidate
                }
            }
        }
    }

    /// Spec order (design/README §4): alphabetical by display name, which also
    /// lands the two dimmed reserve maps last — ANC ANB D2 INF MIR NUKE OVP TRN VRT.
    private var orderedMaps: [GameMap] {
        GameMap.allCases.sorted { $0.displayName < $1.displayName }
    }

    /// SIDE and TYPE share one row, 1:2 with a 16pt gap, per the mock.
    private var sideTypeRow: some View {
        GeometryReader { geo in
            HStack(alignment: .top, spacing: 16) {
                section("SIDE") { sideToggle }
                    .frame(width: (geo.size.width - 16) / 3)
                section("TYPE") { typeRow }
            }
        }
        .frame(height: 56)
    }

    private var sideToggle: some View {
        HStack(spacing: 2) {
            ForEach(Side.allCases) { candidate in
                let selected = side == candidate
                Button {
                    side = candidate
                } label: {
                    Text(candidate.rawValue)
                        .font(Theme.mono(13, weight: selected ? .semibold : .regular))
                        .foregroundStyle(selected ? Theme.sideColor(candidate) : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(
                            selected ? Theme.sideColor(candidate).opacity(0.16) : .clear,
                            in: RoundedRectangle(cornerRadius: Theme.radiusCell)
                        )
                        .overlay {
                            if selected {
                                RoundedRectangle(cornerRadius: Theme.radiusCell)
                                    .stroke(Theme.sideColor(candidate).opacity(0.5), lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusControl))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusControl)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var typeRow: some View {
        HStack(spacing: Theme.gapSmall) {
            ForEach(NadeType.allCases) { candidate in
                selectorCell(isSelected: type == candidate, height: 36) {
                    Circle()
                        .fill(Theme.typeDotColor(candidate))
                        .frame(width: 8, height: 8)
                } action: {
                    type = candidate
                }
                .accessibilityLabel(candidate.displayName)
            }
        }
    }

    private var techniqueControls: some View {
        VStack(alignment: .leading, spacing: Theme.gapSmall) {
            HStack(spacing: Theme.gapSmall) {
                ForEach(ThrowPower.allCases) { candidate in
                    selectorCell(isSelected: power == candidate, height: 34) {
                        Text(candidate.code)
                            .font(Theme.mono(11, weight: power == candidate ? .semibold : .regular))
                            .foregroundStyle(power == candidate ? Theme.accent : Theme.textSecondary)
                    } action: {
                        power = candidate
                    }
                    .accessibilityLabel(candidate.displayName)
                }
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Theme.gapSmall), count: 3),
                spacing: Theme.gapSmall
            ) {
                ForEach(ThrowMovement.allCases) { candidate in
                    selectorCell(isSelected: movement == candidate, height: 34) {
                        Text(candidate.code)
                            .font(Theme.mono(11, weight: movement == candidate ? .semibold : .regular))
                            .foregroundStyle(movement == candidate ? Theme.accent : Theme.textSecondary)
                    } action: {
                        movement = candidate
                    }
                    .accessibilityLabel(candidate.displayName)
                }
            }
            Toggle(isOn: $isBounce) {
                Text("BANK / BOUNCE THROW")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.textSecondary)
            }
            .tint(Theme.accent)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusControl))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusControl)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
            if movement == .jump || movement == .runJump {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 12))
                    Text("Manual jump-throw — binds are banned in comp")
                        .font(.system(size: 12))
                }
                .foregroundStyle(Theme.warning)
            }
        }
    }

    private var calloutFields: some View {
        VStack(alignment: .leading, spacing: Theme.gapSmall) {
            calloutField("Stand callout", text: $standCallout, field: .standCallout)
            calloutField("Target callout", text: $targetCallout, field: .targetCallout)
        }
    }

    private func calloutField(_ placeholder: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(
                "",
                text: text,
                prompt: Text(placeholder).foregroundStyle(Theme.textSecondary)
            )
            .font(.system(size: 15))
            .foregroundStyle(Theme.textPrimary)
            .autocorrectionDisabled()
            .focused($focusedField, equals: field)
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusControl))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusControl)
                    .stroke(Theme.hairline, lineWidth: 1)
            )

            if focusedField == field {
                let suggestions = calloutSuggestions(for: text.wrappedValue)
                if !suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(suggestions, id: \.self) { name in
                                Button {
                                    text.wrappedValue = name
                                    focusedField = nil
                                } label: {
                                    Text(name)
                                        .font(Theme.mono(11))
                                        .foregroundStyle(Theme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .frame(height: 26)
                                        .background(
                                            Theme.surfaceElevated,
                                            in: RoundedRectangle(cornerRadius: Theme.radiusCell)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Theme.radiusCell)
                                                .stroke(Theme.hairline, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func calloutSuggestions(for query: String) -> [String] {
        let all = Callouts.list(for: map)
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let matches = trimmed.isEmpty
            ? all
            : all.filter { $0.localizedCaseInsensitiveContains(trimmed) }
        return Array(matches.prefix(8))
    }

    // MARK: Image slots

    private var imageSlots: some View {
        HStack(spacing: Theme.gapSmall) {
            ForEach(ImageRole.allCases) { role in
                imageSlot(role)
            }
        }
    }

    private func imageSlot(_ role: ImageRole) -> some View {
        Button {
            if drafts[role] != nil {
                editorRole = role
            } else {
                pickerRole = role
                isPickerPresented = true
            }
        } label: {
            ZStack(alignment: .bottom) {
                if let draft = drafts[role] {
                    GeometryReader { geo in
                        Image(uiImage: draft.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                    Text(role.displayName.uppercased())
                        .font(Theme.mono(9))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 18)
                        .background(Theme.bg.opacity(0.75))
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        Text(role.displayName.uppercased())
                            .font(Theme.mono(9))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusControl))
            .overlay {
                if drafts[role] == nil {
                    RoundedRectangle(cornerRadius: Theme.radiusControl)
                        .stroke(
                            Theme.hairline,
                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if drafts[role] != nil {
                Button("Replace image") {
                    pickerRole = role
                    isPickerPresented = true
                }
                Button("Remove image", role: .destructive) { drafts[role] = nil }
            }
        }
    }

    private var notesField: some View {
        TextField(
            "",
            text: $notes,
            prompt: Text("Lineup details, timing, what it blocks…")
                .foregroundStyle(Theme.textSecondary),
            axis: .vertical
        )
        .font(.system(size: 15))
        .foregroundStyle(Theme.textPrimary)
        .lineLimit(3...8)
        .focused($focusedField, equals: .notes)
        .padding(12)
        .frame(minHeight: 72, alignment: .top)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusControl))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusControl)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: Shared selector cell

    private func selectorCell(
        isSelected: Bool,
        height: CGFloat,
        @ViewBuilder content: () -> some View,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(
                    isSelected ? Theme.accentTint : Theme.surface,
                    in: RoundedRectangle(cornerRadius: Theme.radiusCell)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusCell)
                        .stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Save

    private func save() {
        guard !didSave else { return }
        didSave = true

        let target = existing ?? Throw()
        target.map = map
        target.side = side
        target.type = type
        target.title = title.trimmingCharacters(in: .whitespaces)
        target.notes = notes
        target.power = power
        target.movement = movement
        target.isBounce = isBounce
        target.standCallout = standCallout.trimmingCharacters(in: .whitespaces)
        target.targetCallout = targetCallout.trimmingCharacters(in: .whitespaces)
        if existing == nil {
            modelContext.insert(target)
        }

        for (index, role) in ImageRole.allCases.enumerated() {
            let stored = target.image(for: role)
            if let draft = drafts[role] {
                // An aim image always carries a marker, even if the editor was
                // never opened for it.
                let aim = draft.aimPoint
                    ?? (role == .aim ? center(of: draft.cropRect) : nil)
                if let stored, !draft.isNewData {
                    stored.cropRect = draft.cropRect
                    stored.aimPoint = aim
                    stored.sortIndex = index
                } else {
                    // Replaced bytes get a fresh ThrowImage (fresh id), so
                    // id-keyed caches (thumbnails) can't serve stale bitmaps.
                    if let stored {
                        modelContext.delete(stored)
                    }
                    let image = ThrowImage(
                        role: role,
                        imageData: draft.data,
                        cropRect: draft.cropRect,
                        aimPoint: aim,
                        sortIndex: index
                    )
                    // Link via the inverse: unlike `images?.append`, this can't
                    // silently no-op if the optional relationship is ever nil.
                    modelContext.insert(image)
                    image.owner = target
                }
            } else if let stored {
                modelContext.delete(stored)
            }
        }

        target.touch()
        try? modelContext.save()
        dismiss()
    }

    private func center(of crop: NormalizedRect) -> NormalizedPoint {
        let r = crop.clamped()
        return NormalizedPoint(x: r.x + r.width / 2, y: r.y + r.height / 2)
    }
}
