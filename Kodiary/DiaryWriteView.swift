import SwiftUI

struct DiaryWriteView: View {
    @State private var diaryText = ""
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var apiManager = APIManager.shared
    
    @State private var showingLoading = false
    @State private var showingError = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // 제목 (모국어로 표시)
                Text(languageManager.currentLanguage.diaryWriteTitle)
                    .font(.title)
                    .fontWeight(.bold)
                
                // 날짜 (모국어로 표시)
                Text(getCurrentDate())
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // 첨삭 언어 표시
                HStack {
                    Text("✍️")
                    Text(getCorrectionLanguageText())
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    Spacer()
                }
                .padding(.horizontal, 4)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $diaryText)
                        .frame(minHeight: 200)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .disabled(showingLoading)
                    
                    // Placeholder 텍스트 (첨삭 언어에 따라 변경)
                    if diaryText.isEmpty {
                        Text(getCorrectionPlaceholder())
                            .foregroundColor(.gray.opacity(0.7))
                            .padding(.horizontal, 15)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
                
                HStack {
                    Spacer()
                    Text(languageManager.currentLanguage.characterCount(diaryText.count, 500))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Button(languageManager.currentLanguage.analyzeDiaryButton) {
                    Task {
                        await analyzeWithAI()
                    }
                }
                .font(.title2)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(diaryText.isEmpty || showingLoading ? Color.gray : Color.blue)
                .cornerRadius(10)
                .disabled(diaryText.isEmpty || showingLoading)
                
                Spacer()
            }
            .padding()
            
            // 로딩 오버레이
            if showingLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
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
    
    // 현재 날짜 (모국어로 표시)
    func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = languageManager.currentLanguage.locale
        return formatter.string(from: Date())
    }
    
    // 첨삭 언어 표시 텍스트
    func getCorrectionLanguageText() -> String {
        switch languageManager.nativeLanguage.languageCode {
        case "ko":
            return "\(languageManager.correctionLanguage.languageName)로 일기를 써주세요."
        case "en":
            return "Writing in \(languageManager.correctionLanguage.languageName)"
        case "ja":
            return "\(languageManager.correctionLanguage.languageName)で作成"
        default:
            return "Writing in \(languageManager.correctionLanguage.languageName)"
        }
    }
    
    // 첨삭 언어에 따른 placeholder
    func getCorrectionPlaceholder() -> String {
        switch languageManager.correctionLanguage.languageCode {
        case "ko":
            return "오늘 있었던 일을 자유롭게 써보세요."
        case "en":
            return "Write freely about what happened today."
        case "ja":
            return "今日あったことを自由に書いてみてください."
        default:
            return "Write about your day."
        }
    }
    
    // AI 첨삭 분석
    func analyzeWithAI() async {
        showingLoading = true
        
        do {
            print("🤖 AI 첨삭 요청 시작: \(diaryText.prefix(50))...")
            print("📝 첨삭 언어: \(languageManager.correctionLanguage.languageName)")
            print("🌍 설명 언어: \(languageManager.nativeLanguage.languageName)")
            
            // 기존 API 호출 (단일 매개변수)
            // TODO: APIManager를 업데이트하여 첨삭 언어와 설명 언어를 지원하도록 수정 필요
            let corrections = try await apiManager.analyzeDiary(text: diaryText)
            
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
