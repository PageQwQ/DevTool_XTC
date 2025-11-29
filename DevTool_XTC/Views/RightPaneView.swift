import SwiftUI

struct RightPaneView: View {
    @ObservedObject var vm: KeyboardViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(vm.importedURL?.lastPathComponent ?? "未导入文件")
                    .font(.headline)
                Spacer()
                Toggle("成对插入", isOn: $vm.pairModeEnabled)
                Toggle("长按连击", isOn: $vm.repeatEnabled)
            }
            .padding(.horizontal, 8)
            if let err = vm.parseError {
                Text(err).foregroundStyle(.red)
            }
            TextEditor(text: $vm.text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.gray.opacity(0.2))
            VStack(alignment: .leading) {
                Text("统计")
                ForEach(vm.stats.keys.sorted(), id: \.self) { k in
                    HStack { Text(k); Spacer(); Text(String(vm.stats[k] ?? 0)) }
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
