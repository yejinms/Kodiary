import SwiftUI

struct CorrectionResultView: View {
    let originalText: String
    let corrections: [CorrectionItem]
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var languageManager: LanguageManager  // 추가
    
    @State private var expandedItems: Set<Int> = []
    @State private var isSaving = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 원본 일기 표시 (하이라이트 적용)
                VStack(alignment: .leading, spacing: 10) {
                    Text(languageManager.currentLanguage.writtenDiaryTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    // 하이라이트된 텍스트 표시
                    HighlightedText(
                        originalText: originalText,
                        corrections: corrections
                    )
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // 첨삭 완료 헤더
                VStack(spacing: 10) {
                    HStack {
                        Text("🎉")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text(languageManager.currentLanguage.correctionCompleteTitle)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(languageManager.currentLanguage.correctionCompleteSubtitle(corrections.count))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // 첨삭 목록
                VStack(spacing: 10) {
                    ForEach(corrections.indices, id: \.self) { index in
                        CorrectionRow(
                            correction: corrections[index],
                            index: index,
                            isExpanded: expandedItems.contains(index)
                        ) {
                            toggleExpansion(for: index)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(languageManager.currentLanguage.correctionResultTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(languageManager.currentLanguage.saveButton) {
                    saveDiary()
                }
                .fontWeight(.semibold)
                .disabled(isSaving)
            }
        }
    }
    
    func toggleExpansion(for index: Int) {
        if expandedItems.contains(index) {
            expandedItems.remove(index)
        } else {
            expandedItems.insert(index)
        }
    }
    
    @EnvironmentObject var dataManager: DataManager

    func saveDiary() {
        isSaving = true
        
        print("일기 저장 시작...")
        
        // DataManager를 통해 실제 저장
        dataManager.saveDiary(text: originalText, corrections: corrections)
        
        // 저장 애니메이션을 위한 딜레이
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("일기 저장 완료!")
            
            // 홈 화면으로 돌아가기
            navigationPath = NavigationPath()
            
            isSaving = false
        }
    }
}

// 첨삭 항목 행 - 다국어 지원
struct CorrectionRow: View {
    let correction: CorrectionItem
    let index: Int
    let isExpanded: Bool
    let onTap: () -> Void
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더 (항상 보임)
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        // 수정 타입
                        Text(correction.type)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(typeColor.opacity(0.2))
                            .foregroundColor(typeColor)
                            .cornerRadius(8)
                        
                        // 수정 내용 요약
                        Text("\"\(correction.original)\" → \"\(correction.corrected)\"")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    // 펼치기 아이콘
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 상세 내용 (펼쳤을 때만 보임)
            if isExpanded {
                VStack(alignment: .leading, spacing: 15) {
                    Divider()
                    
                    // 원본
                    VStack(alignment: .leading, spacing: 5) {
                        Text(languageManager.currentLanguage.originalExpressionTitle)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("\"\(correction.original)\"")
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // 화살표
                    HStack {
                        Spacer()
                        Text("⬇️")
                            .font(.title2)
                        Spacer()
                    }
                    
                    // 수정안
                    VStack(alignment: .leading, spacing: 5) {
                        Text(languageManager.currentLanguage.correctionSuggestionTitle)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("\"\(correction.corrected)\"")
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // 설명
                    VStack(alignment: .leading, spacing: 5) {
                        Text(languageManager.currentLanguage.explanationTitle)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text(correction.explanation)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    // 수정 타입별 색상
    var typeColor: Color {
        switch correction.type {
        case "문법", "Grammar", "文法":
            return .orange
        case "맞춤법", "Spelling", "スペル":
            return .red
        case "표현", "Expression", "表現":
            return .purple
        default:
            return .gray
        }
    }
}

// 하이라이트된 텍스트 컴포넌트 (변경 없음)
struct HighlightedText: View {
    let originalText: String
    let corrections: [CorrectionItem]
    
    var body: some View {
        Text(attributedString)
            .lineSpacing(4)
    }
    
    private var attributedString: AttributedString {
        var result = AttributedString(originalText)
        
        // 모든 correction의 original 텍스트를 찾아서 하이라이트
        for correction in corrections {
            let searchText = correction.original
            
            // 대소문자 구분 없이 검색
            if let range = result.range(of: searchText, options: [.caseInsensitive]) {
                // 빨간 글씨색 적용
                result[range].foregroundColor = .red
                
                // 빨간 배경색 (형광펜 효과) 적용
                result[range].backgroundColor = Color.red.opacity(0.2)
                
                // 볼드체 적용 (더 눈에 띄게)
                result[range].font = .system(size: 16, weight: .semibold)
            }
        }
        
        return result
    }
}
