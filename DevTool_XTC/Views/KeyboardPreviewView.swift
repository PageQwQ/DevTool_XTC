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
            if let cat = currentCategory, let first = cat.symbols.first {
                let header = first.text.hasPrefix("\\") ? String(first.text.dropFirst()) : first.text
                if !header.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "text.quote")
                        Text(header)
                            .lineLimit(2)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.25)))
                    .padding(.horizontal, 8)
                }
            }
            if let cat = currentCategory {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: max(1, cat.column))
                let visible = Array(cat.symbols.dropFirst())
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(visible) { item in
                            let display = item.text.hasPrefix("\\") ? String(item.text.dropFirst()) : item.text
                            let isWide = display.count > 5
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(display.isEmpty ? 0.05 : (isWide ? 0.25 : 0.2)))
                                Text(display)
                                    .font(isWide ? .headline : .title3)
                                    .foregroundStyle(display.isEmpty ? .clear : .primary)
                            }
                            .frame(minWidth: 44, minHeight: 44)
                            .gridCellColumns(isWide ? min(4, max(1, cat.column)) : 1)
                            .onTapGesture { vm.insert(item) }
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
