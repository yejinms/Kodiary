import SwiftUI

struct DiaryWriteView: View {
    @State private var diaryText = ""
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var apiManager = APIManager.shared
    
    @State private var showingLoading = false
    @State private var showingError = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("오늘의 일기")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(getCurrentDate())
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextEditor(text: $diaryText)
                    .frame(minHeight: 200)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .disabled(showingLoading)
                
                HStack {
                    Spacer()
                    Text("\(diaryText.count)/500")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Button("첨삭받기") {
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
        .navigationTitle("일기 쓰기")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: CorrectionData.self) { correctionData in
            CorrectionResultView(
                originalText: correctionData.originalText,
                corrections: correctionData.corrections,
                navigationPath: $navigationPath
            )
        }
        .alert("첨삭 오류", isPresented: $showingError) {
            Button("확인") { }
            Button("다시 시도") {
                Task { await analyzeWithAI() }
            }
        } message: {
            Text(apiManager.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
    }
    
    func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "ko_KR")
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
