//
//  KodiaryApp.swift
//  Kodiary
//
//  Created by Niko on 6/19/25.
//

import SwiftUI

@main
struct KodiaryApp: App {
    let dataManager = DataManager.shared
    let userManager = UserManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(dataManager)
                .environmentObject(LanguageManager.shared)
                .environmentObject(userManager)
        }
    }
}

struct MainAppView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var viewId = UUID()
    
    var body: some View {
        Group {
            if !userManager.isLoggedIn {
                LoginView()
                    .environmentObject(LanguageManager.shared)
                    .environmentObject(userManager)
                    .onAppear {
                        print("🔐 LoginView 표시됨")
                    }
            } else if userManager.needsNameSetup {
                NameSetupView()
                    .environmentObject(LanguageManager.shared)
                    .environmentObject(userManager)
                    .onAppear {
                        print("📝 NameSetupView 표시됨")
                    }
            } else if userManager.needsLanguageSetup {
                LanguageLearningSetupView()
                    .environmentObject(LanguageManager.shared)
                    .environmentObject(userManager)
                    .onAppear {
                        print("🌍 LanguageLearningSetupView 표시됨")
                    }
            } else {
                ContentView()
                    .environmentObject(DataManager.shared)
                    .environmentObject(LanguageManager.shared)
                    .environmentObject(userManager)
                    .onAppear {
                        print("🏠 ContentView 표시됨 - 사용자: \(userManager.userName)")
                    }
            }
        }
        .id(viewId)
        .onReceive(userManager.$isLoggedIn) { isLoggedIn in
            print("🔄 MainAppView - 로그인 상태 변경됨: \(isLoggedIn)")
            viewId = UUID()
        }
        .onReceive(userManager.$needsNameSetup) { needsSetup in
            print("🔄 MainAppView - 이름 설정 필요 상태 변경됨: \(needsSetup)")
            viewId = UUID()
        }
        .onReceive(userManager.$needsLanguageSetup) { needsSetup in
            print("🔄 MainAppView - 언어 설정 필요 상태 변경됨: \(needsSetup)")
            viewId = UUID()
        }
    }
}
