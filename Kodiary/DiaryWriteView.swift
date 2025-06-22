import SwiftUI

struct DiaryWriteView: View {
    @State private var diaryText = ""
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var apiManager = APIManager.shared
    
    @State private var showingLoading = false
    @State private var showingError = false
    
    // ContentView와 동일한 날짜 관련 computed properties
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
    
    var body: some View {
        ZStack {
            VStack {
                
                Spacer()
                    .frame(height: 26)
                // ContentView와 동일한 날짜 헤더
                ResponsiveDateHeader(dateComponents: todayDateComponents)
            
                
                VStack(spacing: 10) {
                    // ContentView와 동일한 원형 날짜 표시
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
                    }
                    .padding(.top, 10)
                    
                    // 첨삭 언어 표시
                    HStack {
                        HStack{
                            Text("✍️")
                            Text(getCorrectionLanguageText())
                                .font(.buttonFontSmall)
                                .foregroundColor(.primaryDark)
//                                .padding(.horizontal, 2)
                        }
                        .padding(.horizontal, 5)
                        .background(Color.primaryYellow.opacity(0.5))
                        Spacer()
                        // 글자 수 표시
                        HStack {
                            Spacer()
                            Text(languageManager.currentLanguage.characterCount(diaryText.count, 160))
                                .font(.buttonFontSmall)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    
                    // 줄 노트 스타일 및 폰트 스타일
                    ZStack(alignment: .topLeading) {
                        // 배경
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(minHeight: 180)
                            .cornerRadius(10)
                        
                        // 줄 노트처럼 선들 추가
                        VStack(spacing: 34) {
                            ForEach(0..<5, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.primaryDark.opacity(0.4))
                                    .frame(height: 1)
                            }
                        }
                        .padding(.top, 38)
                        .padding(.horizontal, 10)
                        
                        TextEditor(text: $diaryText)
                            .font(.handWrite)
                            .frame(minHeight: 180)
                            .padding(5)
                            .background(Color.clear)
                            .disabled(showingLoading)
                            .scrollContentBackground(.hidden)
                            .lineSpacing(10)
                        
                        // Placeholder 텍스트 (첨삭 언어에 따라 변경)
                        if diaryText.isEmpty {
                            Text(getCorrectionPlaceholder())
                                .font(.handWrite)
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.horizontal, 15)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, 25)
                    
                    // 첨삭 버튼
                    Button(
                        languageManager.currentLanguage.analyzeDiaryButton) {
                        Task {
                            await analyzeWithAI()
                        }
                    }
                    .font(.buttonFont)
                    .foregroundColor(.primaryDark)
                    .frame(width: 350, height: 50)
                    .background(diaryText.isEmpty || showingLoading ? Color.primaryDark.opacity(0.2) : Color.primaryBlue)
                    Spacer()
                }
            }
            
            // 로딩 오버레이
            if showingLoading {
                LoadingView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: CorrectionData.self) { correctionData in
            CorrectionResultView(
                originalText: correctionData.originalText,
                corrections: correctionData.corrections,
                navigationPath: $navigationPath
            )
            .environmentObject(dataManager)
            .environmentObject(languageManager)
        }
        .alert(languageManager.currentLanguage.errorTitle, isPresented: $showingError) {
            Button(languageManager.currentLanguage.confirmButton) { }
            Button(languageManager.currentLanguage.retryButton) {
                Task { await analyzeWithAI() }
            }
        } message: {
            Text(apiManager.errorMessage ?? languageManager.currentLanguage.unknownErrorMessage)
        }
    }
    
    // 첨삭 언어 표시 텍스트
    func getCorrectionLanguageText() -> String {
        let correctionLanguageName = languageManager.nativeLanguage.languageNameTranslations[languageManager.correctionLanguage.languageCode] ?? languageManager.correctionLanguage.languageName
        
        switch languageManager.nativeLanguage.languageCode {
        case "ko": return "\(correctionLanguageName)로 써주세요"
        case "en": return "Please write in \(correctionLanguageName)"
        case "ja": return "\(correctionLanguageName)で書いてください"
        default: return "Please write in \(correctionLanguageName)"
        }
    }
    
    // 첨삭 언어에 따른 placeholder
    func getCorrectionPlaceholder() -> String {
        switch languageManager.correctionLanguage.languageCode {
        case "ko":
            return "오늘 있었던 일을 자유롭게 써보세요..."
        case "en":
            return "Write freely about what happened today..."
        case "ja":
            return "今日あったことを자由に書いてみてください..."
        default:
            return "Write about your day..."
        }
    }
    
    // AI 첨삭 분석 (다국어 지원)
    func analyzeWithAI() async {
        showingLoading = true
        let startTime = Date()
        
        do {
            print("🤖 AI 첨삭 요청 시작: \(diaryText.prefix(50))...")
            print("📝 첨삭 언어: \(languageManager.correctionLanguage.languageName)")
            print("🌍 설명 언어: \(languageManager.nativeLanguage.languageName)")
            
            // 새로운 다국어 지원 API 호출
            let corrections = try await apiManager.analyzeDiary(
                text: diaryText,
                correctionLanguage: languageManager.correctionLanguageCode,
                explanationLanguage: languageManager.nativeLanguageCode
            )
            
            // 최소 1.5초 대기
            let elapsedTime = Date().timeIntervalSince(startTime)
            if elapsedTime < 1.5 {
                try await Task.sleep(nanoseconds: UInt64((2.0 - elapsedTime) * 1_000_000_000))
            }
            
            print("✅ AI 첨삭 완료: \(corrections.count)개 수정점")
            
            let correctionData = CorrectionData(
                originalText: diaryText,
                corrections: corrections
            )
            
            await MainActor.run {
                showingLoading = false
                navigationPath.append(correctionData)
            }
            
        } catch {
            print("❌ AI 첨삭 에러: \(error)")
            
            await MainActor.run {
                showingLoading = false
                showingError = true
            }
        }
    }
}
