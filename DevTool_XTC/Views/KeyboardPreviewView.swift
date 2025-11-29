import SwiftUI

struct KeyboardPreviewView: View {
    @ObservedObject var vm: KeyboardViewModel
    @State private var popoverItem: SymbolItem?

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(vm.categories.enumerated()), id: \.offset) { idx, cat in
                        Button(cat.name.isEmpty ? "无名" : cat.name) {
                            vm.currentIndex = idx
                        }
                        .foregroundStyle(vm.currentIndex == idx ? .primary : .secondary)
                    }
                }
                .padding(.horizontal, 8)
            }
            if let comment = currentCategory?.comment, !comment.isEmpty {
                Text(comment)
                    .lineLimit(1)
                    .font(.headline)
            }
            if let cat = currentCategory {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: max(1, cat.column))
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(cat.symbols) { item in
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(item.text.isEmpty ? 0.05 : 0.2))
                                Text(item.text)
                                    .font(.title3)
                                    .foregroundStyle(item.text.isEmpty ? .clear : .primary)
                            }
                            .frame(minWidth: 44, minHeight: 44)
                            .onTapGesture {
                                vm.insert(item)
                            }
                            .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
                                if pressing {
                                    if item.left != nil || item.right != nil {
                                        popoverItem = item
                                    } else {
                                        vm.startRepeating(item: item)
                                    }
                                } else {
                                    vm.stopRepeating()
                                }
                            }, perform: {})
                            .contextMenu {
                                if let l = item.left { Button(l) { vm.text.append(l) } }
                                if let r = item.right { Button(r) { vm.text.append(r) } }
                                if item.left != nil || item.right != nil { Button("成对") { vm.insert(item) } }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } else {
                Text("未选择分栏")
            }
            HStack {
                Button("⌫") { vm.backspace() }
                Spacer()
                Button("发送") {}
            }
            .padding(.horizontal, 8)
        }
        .overlay(alignment: .center) {
            if let item = popoverItem {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { popoverItem = nil }
                    VStack(spacing: 8) {
                        if let l = item.left { Button(l) { vm.text.append(l); popoverItem = nil } }
                        if item.left != nil && item.right != nil { Button("成对插入") { vm.insert(item); popoverItem = nil } }
                        if let r = item.right { Button(r) { vm.text.append(r); popoverItem = nil } }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.9)))
                }
            }
        }
    }

    private var currentCategory: SymbolCategory? {
        guard vm.categories.indices.contains(vm.currentIndex) else { return nil }
        return vm.categories[vm.currentIndex]
    }
}
