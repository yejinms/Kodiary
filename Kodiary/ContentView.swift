//
//  ContentView.swift
//  Kodiary
//
//  Created by Niko on 6/19/25.
//

import SwiftUI

// ResponsiveDateHeader 컴포넌트
struct ResponsiveDateHeader: View {
    let dateComponents: (year: String, month: String, weekday: String)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .frame(width: geometry.size.width, height: 70)
                    .foregroundColor(.clear)
                    .overlay(
                       VStack(spacing: 0) {
                           Rectangle()
                               .fill(Color.primaryDark.opacity(0.2))
                               .frame(height: 1.8)
                           
                           Spacer()
                           
                           Rectangle()
                               .fill(Color.primaryDark.opacity(0.2))
                               .frame(height: 1.8)
                       }
                       .padding(.horizontal, 0.9)
                    )
                
                HStack(spacing: 0) {
                    // 연도
                    Text(dateComponents.year)
                        .font(.titleLarge)
                        .foregroundColor(.primaryDark)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    
                    // 월
                    Text(dateComponents.month)
                        .font(.titleLarge)
                        .foregroundColor(.primaryDark)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    
                    // 요일
                    Text(dateComponents.weekday)
                        .font(.titleLarge)
                        .foregroundColor(.primaryDark)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
            }
        }
        .frame(height: 70)
    }
}

struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    @State private var showingLanguageSelection = false
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    
    // 오늘 일기 작성 여부 확인
    var hasTodayDiary: Bool {
        let today = Date()
        return dataManager.getDiary(for: today) != nil
    }
    
    // 사용자 이름 (실제로는 UserDefaults나 다른 곳에서 가져올 수 있음)
    var username: String {
        return "Niko" // 나중에 실제 사용자 이름으로 변경 가능
    }
    
    // 오늘 날짜의 각 구성 요소들 (다국어 지원)
    var todayDateComponents: (year: String, month: String, weekday: String) {
        let today = Date()
        let components = languageManager.currentLanguage.dateComponents
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        
        formatter.dateFormat = components.year
        let year = formatter.string(from: today)
        
        formatter.dateFormat = components.month
        let month = formatter.string(from: today)
        
        formatter.dateFormat = components.weekday
        let weekday = formatter.string(from: today)
        
        return (year, month, weekday)
    }
    
    var todayDayString: String {
        let today = Date()
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        formatter.dateFormat = languageManager.currentLanguage.dayDateFormat
        return formatter.string(from: today)
    }
    
    // 인사말 (다국어 지원)
    var greetingTexts: (title: String, subtitle: String) {
        if hasTodayDiary {
            return languageManager.currentLanguage.greetingWithDiary(username)
        } else {
            return languageManager.currentLanguage.greetingWithoutDiary(username)
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: Spacing.md) {
                
                Spacer()
                    .frame(height: 10)
                
                // 반응형 날짜 헤더 사용
                ResponsiveDateHeader(dateComponents: todayDateComponents)
        
                ZStack {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 265.5, height: 265.5)
                        .cornerRadius(265.5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 265.5)
                                .inset(by: 0.9)
                                .stroke(Color.primaryDark, lineWidth: 1.8)
                        )
                    
                    VStack(spacing: Spacing.sm) {
                        Text(todayDayString)
                            .font(.titleHuge)
                            .foregroundColor(.primaryDark)
                        
                    }
                }.padding(.top, 18)
                
                // 인사말 (다국어 지원)
                VStack(spacing: Spacing.sm) {
                    Text(greetingTexts.title)
                        .font(.titleSmall1)
                        .foregroundColor(.primaryDark)
                    Text(greetingTexts.subtitle)
                        .font(.titleSmall2)
                        .foregroundColor(.primaryDark)
                        .padding(.top, 4)
                        .multilineTextAlignment(.center)
                }
                .padding(Spacing.xl)
                .cornerRadius(CornerRadius.md)
                
                // 일기 쓰기 버튼 (다국어 지원)
                Button(action: {
                    navigationPath.append("diary-write")
                }) {
                    HStack(spacing: Spacing.sm) {
                        Text(hasTodayDiary ? languageManager.currentLanguage.writeButtonCompletedText(languageManager.correctionLanguageDisplayName) : languageManager.currentLanguage.writeButtonText(languageManager.correctionLanguageDisplayName))
                            .font(.buttonFont)
                            .padding(16)
                        
                        Spacer()
                        Image(systemName: "plus")
                            .font(.buttonFontSmall)
                            .padding(16)
                    }
                    .foregroundColor(.primaryDark)
                    .frame(width: 350, height: 50)
                    .background(hasTodayDiary ? Color.primaryDark.opacity(0.2) : Color.primaryBlue )
                }
                
                // 히스토리 버튼 (다국어 지원)
                Button(action: {
                    navigationPath.append("diary-history")
                }) {
                    HStack(spacing: Spacing.sm) {
                        Text(languageManager.currentLanguage.historyButtonText)
                            .font(.buttonFont)
                            .padding(16)
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .font(.buttonFontSmall)
                            .padding(16)
                    }
                }
                .font(.buttonFont)
                .foregroundColor(.primaryDark)
                .frame(width: 350, height: 50)
                .background(Color.primaryYellow)
                
                Spacer()
            }
//            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // 언어 설정 버튼 (좌측 상단)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingLanguageSelection = true
                    }) {
                        Circle()
                            .fill(Color.background)
                            .frame(width: 45, height: 45)
                            .overlay(
                                Text(languageManager.currentCorrectionLanguage.flag)
                                    .font(.system(size: 35))
                            )
                    }
                }
                
                // 프로필 설정 버튼 (우측 상단)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        navigationPath.append("profile-settings")
                    }) {
                        Circle()
                            .fill(Color.background)
                            .frame(width: 45, height: 45)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.primaryDark)
                            )
                    }
                }
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "diary-write":
                    DiaryWriteView(
                        navigationPath: $navigationPath
                    )
                case "diary-history":
                    DiaryHistoryView(
                                navigationPath: $navigationPath
                            )
                case "profile-settings":
                    ProfileSettingsView()
                        .environmentObject(languageManager)
                default:
                    Text("Unknown destination")
                }
            }
            .sheet(isPresented: $showingLanguageSelection) {
                LanguageSelectionView()
                    .environmentObject(languageManager)
            }
        }
        .onAppear {
            // 앱 시작 시 데이터 새로고침
            dataManager.fetchDiaries()
            FontNameChecker.checkActualFontNames()
            
        }
    }
}

struct FontNameChecker {
    static func checkActualFontNames() {
        print("=== 실제 폰트 이름 확인 ===")
        
        let fontFiles = [
            "ChosunKm.TTF",
            "ChosunNm.ttf",
            "ChosunSm.TTF",
            "YoonChild.otf",
            "산돌국대떡볶이체.otf",
            "Cafe24Classictype-v1.1.ttf",
            "GravitasOne-Regular.ttf",
            "이서윤체.ttf"
        ]
        
        for fileName in fontFiles {
            let nameWithoutExtension = (fileName as NSString).deletingPathExtension
            let fileExtension = (fileName as NSString).pathExtension
            
            if let fontPath = Bundle.main.path(forResource: nameWithoutExtension, ofType: fileExtension),
               let fontData = NSData(contentsOfFile: fontPath),
               let dataProvider = CGDataProvider(data: fontData),
               let cgFont = CGFont(dataProvider) {
                
                if let postScriptName = cgFont.postScriptName {
                    print("📄 파일: \(fileName)")
                    print("   실제 폰트 이름: \(postScriptName)")
                    print("   가정한 이름: \(nameWithoutExtension)")
                    print("   일치 여부: \(postScriptName as String == nameWithoutExtension ? "✅" : "❌")")
                    print()
                }
            }
        }
        
        // 현재 사용 가능한 모든 폰트 중에서 "Chosun"이나 "Yoon" 포함된 것들 찾기
        print("=== 'Chosun' 또는 'Yoon' 포함 폰트 검색 ===")
        for family in UIFont.familyNames {
            if family.lowercased().contains("chosun") || family.lowercased().contains("yoon") {
                print("📁 Family: \(family)")
                for fontName in UIFont.fontNames(forFamilyName: family) {
                    print("   • \(fontName)")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DataManager.shared)
            .environmentObject(LanguageManager.shared)
    }
}
