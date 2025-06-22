import SwiftUI

struct DiaryWriteView: View {
    @State private var diaryText = ""
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager  // 추가
    @StateObject private var apiManager = APIManager.shared
    
    @State private var showingLoading = false
    @State private var showingError = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text(languageManager.currentLanguage.diaryWriteTitle)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(getCurrentDate())
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $diaryText)
                        .frame(minHeight: 200)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .disabled(showingLoading)
                    
                    // Placeholder 텍스트 (TextEditor에는 placeholder가 없어서 수동 구현)
                    if diaryText.isEmpty {
                        Text(languageManager.currentLanguage.diaryWritePlaceholder)
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
    
    func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = languageManager.currentLanguage.locale
        return formatter.string(from: Date())
    }
    
    // AI 첨삭 분석
    func analyzeWithAI() async {
        showingLoading = true
        
        do {
            print("🤖 AI 첨삭 요청 시작: \(diaryText.prefix(50))...")
            
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
