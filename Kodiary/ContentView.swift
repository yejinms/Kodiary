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
        .padding(.top, -15)
    }
}

struct ContentView: View {
    @State private var showingDailyLimitAlert = false //일일 한도 알림
    @State private var currentDate = Date()
    @State private var navigationPath = NavigationPath()
    @State private var showingLanguageSelection = false
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var userManager: UserManager
    
    // 오늘 일기 작성 여부 확인
    var hasTodayDiary: Bool {
        let today = Date()
        return dataManager.getDiary(for: currentDate) != nil
    }
    
    // 사용자 이름
    var username: String {
        return userManager.userName.isEmpty ? "사용자" : userManager.userName
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
            VStack(spacing: 0) {
                // 사용자 정의 툴바
                HStack {
                    // 언어 설정 버튼 (좌측)
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
                    
                    Spacer()
                    
                    // 프로필 설정 버튼 (우측)
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
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                
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
                            .lineSpacing(10)
                            .padding(.horizontal)
                    }
                    .padding(Spacing.xl)
                    .cornerRadius(CornerRadius.md)
                    
                    // 🆕 일기 쓰기 버튼 (제한 로직 추가)
                    Button(action: {
                        if hasTodayDiary {
                            showingDailyLimitAlert = true
                        } else {
                            navigationPath.append("diary-write")
                        }
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
            }
            .navigationBarHidden(true) // 기본 네비게이션 바 숨기기
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
                        .environmentObject(userManager)
                    
                default:
                    Text("Unknown destination")
                }
            }
            .alert(languageManager.currentLanguage.dailyDiaryLimitTitle, isPresented: $showingDailyLimitAlert) {
                Button(languageManager.currentLanguage.confirmButton) { }
            } message: {
                Text(languageManager.currentLanguage.dailyDiaryLimitMessage)
            }
            .sheet(isPresented: $showingLanguageSelection) {
                LanguageSelectionView()
                    .environmentObject(languageManager)
            }
        }
        .onAppear {
            print("🏠 ContentView 나타남")
            print("👤 현재 사용자: \(userManager.userName)")
            print("🌍 현재 첨삭 언어: \(languageManager.correctionLanguageCode)")
            print("📚 현재 일기 수: \(dataManager.savedDiaries.count)")
            
            // 항상 앱 시작 시 데이터 새로고침 실행
            dataManager.refreshDataOnAppStart()
            
            // CloudKit 계정 상태 확인
            if dataManager.syncStatus == "확인 중..." {
                dataManager.checkCloudKitAccount()
            }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            let newDate = Date()
            if !Calendar.current.isDate(currentDate, inSameDayAs: newDate) {
                print("📅 날짜 변경 감지: \(currentDate) → \(newDate)")
                currentDate = newDate
                dataManager.fetchDiaries() // 데이터 새로고침으로 UI 업데이트
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            let newDate = Date()
            if !Calendar.current.isDate(currentDate, inSameDayAs: newDate) {
                print("📱 포그라운드 복귀 시 날짜 업데이트: \(currentDate) → \(newDate)")
                currentDate = newDate
                dataManager.fetchDiaries()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DataManager.shared)
            .environmentObject(LanguageManager.shared)
            .environmentObject(UserManager.shared)
    }
}
