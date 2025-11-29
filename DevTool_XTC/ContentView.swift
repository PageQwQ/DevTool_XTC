//
//  ContentView.swift
//  DevTool_XTC
//
//  Created by PageQwQ on 2025/11/29.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var vm = KeyboardViewModel()

    var body: some View {
        Group {
            if vm.categories.isEmpty {
                OnboardingView(vm: vm)
            } else {
                HStack(spacing: 0) {
                    KeyboardPreviewView(vm: vm)
                        .frame(minWidth: 320)
                        .padding()
                    Divider()
                    RightPaneView(vm: vm)
                        .frame(minWidth: 320)
                        .padding()
                }
            }
        }
        .onAppear {
            vm.loadLastBookmarkIfAvailable()
        }
    }
}

#Preview {
    ContentView()
}
