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
                VStack(alignment: .leading, spacing: 6) {
                    Text("解析错误")
                        .font(.headline)
                    Text(err)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 1))
            }
            ScrollView {
                Text(vm.xmlSource.isEmpty ? "未加载 XML 源代码" : vm.xmlSource)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .border(Color.gray.opacity(0.2))
            
        }
    }
}
