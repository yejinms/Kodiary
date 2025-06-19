import SwiftUI

struct DiaryWriteView: View {
    @State private var diaryText = ""
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
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
            
            HStack {
                Spacer()
                Text("\(diaryText.count)/500")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Button("첨삭받기") {
                if !diaryText.isEmpty {
                    checkDiary()
                }
            }
            .font(.title2)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(diaryText.isEmpty ? Color.gray : Color.blue)
            .cornerRadius(10)
            .disabled(diaryText.isEmpty)
            
            Spacer()
        }
        .padding()
        .navigationTitle("일기 쓰기")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: CorrectionData.self) { correctionData in
            CorrectionResultView(
                originalText: correctionData.originalText,
                corrections: correctionData.corrections,
                navigationPath: $navigationPath
            )
        }
    }
    
    func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: Date())
    }
    
    func checkDiary() {
        print("일기 내용: \(diaryText)")
        
        // 첨삭 결과 데이터 생성
        let correctionData = CorrectionData(
            originalText: diaryText,
            corrections: getSampleCorrections()
        )
        
        // 첨삭 결과 화면으로 이동
        navigationPath.append(correctionData)
    }
    
    func getSampleCorrections() -> [CorrectionItem] {
        return [
            CorrectionItem(
                original: "좋다",
                corrected: "좋아요",
                explanation: "존댓말로 써주세요. '좋다'보다 '좋아요'가 자연스러워요.",
                type: "문법"
            ),
            CorrectionItem(
                original: "재미있었다",
                corrected: "재미있었어요",
                explanation: "존댓말로 일관성 있게 써주세요.",
                type: "문법"
            )
        ]
    }
}
