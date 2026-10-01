import SwiftUI

struct PresetsBar: View {
    @ObservedObject var vm: RecordingViewModel
    @ObservedObject private var presets: PresetsStore
    @State private var showSaveSheet = false
    @State private var newPresetName: String = ""

    init(vm: RecordingViewModel) {
        self.vm = vm
        self._presets = ObservedObject(wrappedValue: vm.presets)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "slider.horizontal.3").foregroundStyle(.secondary)
            Menu {
                if presets.presets.isEmpty {
                    Text("No presets saved").foregroundStyle(.secondary)
                } else {
                    ForEach(presets.presets) { p in
                        Button {
                            vm.apply(p)
                        } label: {
                            Text(p.name)
                        }
                    }
                    Divider()
                    Menu("Delete preset…") {
                        ForEach(presets.presets) { p in
                            Button(role: .destructive) {
                                presets.delete(id: p.id)
                            } label: {
                                Text(p.name)
                            }
                        }
                    }
                }
            } label: {
                Text("Presets")
            }
            .menuStyle(.borderlessButton)
            .frame(maxWidth: 100)
            .id(presets.presets)

            Button("Save current…") {
                newPresetName = "Preset \(presets.presets.count + 1)"
                showSaveSheet = true
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .sheet(isPresented: $showSaveSheet) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Save current settings as preset").font(.headline)
                TextField("Name", text: $newPresetName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)
                HStack {
                    Spacer()
                    Button("Cancel") { showSaveSheet = false }
                    Button("Save") {
                        let trimmed = newPresetName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        vm.saveCurrentAsPreset(named: trimmed)
                        showSaveSheet = false
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
    }
}
