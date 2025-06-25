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
            } else if userManager.isSettingsLoaded {
                ContentView()
                    .environmentObject(DataManager.shared)
                    .environmentObject(LanguageManager.shared)
                    .environmentObject(userManager)
                    .onAppear {
                        print("🏠 ContentView 표시됨 - 사용자: \(userManager.userName)")
                    }
            } else {
                // 설정 로드 중 - 깔끔한 배경만 표시
                Color.background
                    .ignoresSafeArea()
                    .onAppear {
                        print("⏳ 설정 로드 대기 중...")
                    }
            }
        }
        .id(viewId)
        .onReceive(userManager.$isLoggedIn) { newValue in
            print("🔄 MainAppView - 로그인 상태 변경됨: \(newValue)")
            viewId = UUID()
        }
        .onReceive(userManager.$needsNameSetup) { newValue in
            print("🔄 MainAppView - 이름 설정 필요 상태 변경됨: \(newValue)")
            viewId = UUID()
        }
        .onReceive(userManager.$isSettingsLoaded) { newValue in
            print("🔄 MainAppView - 설정 로드 상태 변경됨: \(newValue)")
            viewId = UUID()
        }
    }
}

// CloudKit 동기화 대기 화면
struct CloudKitSyncWaitingView: View {
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 로딩 애니메이션
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryDark))
                    .scaleEffect(1.5)
                
                Text("☁️")
                    .font(.system(size: 60))
                    .opacity(0.8)
            }
            
            VStack(spacing: 12) {
                Text("데이터 동기화 중...")
                    .font(.titleLarge)
                    .foregroundColor(.primaryDark)
                
                Text("클라우드에서 설정과 일기를 불러오고 있어요")
                    .font(.bodyFont)
                    .foregroundColor(.primaryDark.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(5)
            }
            
            Spacer()
        }
        .background(Color.background)
    }
}
