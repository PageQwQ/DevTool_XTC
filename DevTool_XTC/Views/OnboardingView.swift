import SwiftUI
import UniformTypeIdentifiers

struct OnboardingView: View {
    @ObservedObject var vm: KeyboardViewModel
    @State private var showImporter = false

    var body: some View {
        VStack(spacing: 16) {
            Text("导入键盘 XML 文件以开始")
                .font(.title2)
            HStack(spacing: 12) {
                Button("选择文件") { showImporter = true }
                Button("使用示例") {
                    if let url = Bundle.main.url(forResource: "symbol", withExtension: "xml") {
                        vm.importXML(url: url)
                    } else {
                        vm.parseError = "未找到示例 XML，请使用‘选择文件’导入。"
                    }
                }
            }
            if let err = vm.parseError {
                VStack(alignment: .leading, spacing: 6) {
                    Text("导入错误")
                        .font(.headline)
                    Text(err)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 1))
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [UTType.xml]) { res in
            switch res {
            case .success(let url): vm.importXML(url: url)
            case .failure: break
            }
        }
        .onAppear { vm.loadLastBookmarkIfAvailable() }
        .padding()
    }
}
