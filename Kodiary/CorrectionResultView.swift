import SwiftUI

struct CorrectionResultView: View {
    let originalText: String
    let corrections: [CorrectionItem]
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var dataManager: DataManager
    
    @State private var expandedItems: Set<Int> = []
    @State private var showSaveLoading = false
    @State private var scrollToTop = false
    
    // 원문에서의 위치 순서대로 정렬된 첨삭 결과
    var sortedCorrections: [CorrectionItem] {
        return corrections.sorted { correction1, correction2 in
            let range1 = originalText.range(of: correction1.original, options: [.caseInsensitive])
            let range2 = originalText.range(of: correction2.original, options: [.caseInsensitive])
            
            guard let r1 = range1, let r2 = range2 else {
                // 만약 찾을 수 없다면 원래 순서 유지
                return false
            }
            
            // 원문에서 먼저 나타나는 순서대로 정렬
            return r1.lowerBound < r2.lowerBound
        }
    }
    
    // DiaryWriteView와 동일한 날짜 관련 computed properties
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
            // 메인 컨텐츠
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        Spacer()
                            .frame(height: 16)
                            .id("top") // 스크롤 상단 식별자
                        
                        // DiaryWriteView와 동일한 날짜 헤더
                        ResponsiveDateHeader(dateComponents: todayDateComponents)
                        
                        VStack(spacing: 16) {
                            // DiaryWriteView와 동일한 원형 날짜 표시
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
                            
                            // 첨삭 완료 상태 표시
                            HStack {
                                HStack{
                                    Image(systemName: "checkmark")
                                        .font(.buttonFontSmall)
                                        .foregroundColor(.primaryDark)
                                    Text("첨삭 완료")
                                        .font(.buttonFontSmall)
                                        .foregroundColor(.primaryDark)
                                }
                                .padding(5)
                                .background(Color.primaryYellow.opacity(0.3))
                                Spacer()
                                // 첨삭 개수 표시
                                HStack {
                                    Text(languageManager.currentLanguage.correctionCompleteSubtitle(sortedCorrections.count))
                                        .font(.buttonFontSmall)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                            }
                            .padding(.horizontal, 20)
                            
                            // 작성된 텍스트 영역 (하이라이트 포함)
                            ZStack(alignment: .topLeading) {
                                // 배경
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(minHeight: 180)
                                
                                // 줄 노트처럼 선들 추가
                                VStack(spacing: 34) {
                                    ForEach(0..<6, id: \.self) { _ in
                                        Rectangle()
                                            .fill(Color.primaryDark.opacity(0.4))
                                            .frame(height: 1)
                                    }
                                }
                                .padding(.top, 38)
                                .padding(.horizontal, 10)
                                
                                // 하이라이트된 텍스트 (정렬된 첨삭 사용)
                                ScrollView {
                                    HighlightedText(
                                        originalText: originalText,
                                        corrections: sortedCorrections
                                    )
                                    .font(.handWrite)
                                    .lineSpacing(17)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(15)
                                }
                                .frame(minHeight: 230)
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                            }
                            .padding(.horizontal, 25)
                            
                            // 첨삭 결과 섹션 (정렬된 순서로 표시)
                            VStack(spacing: 16) {
                                // 첨삭 목록 - sortedCorrections 사용
                                VStack(spacing: 10) {
                                    ForEach(sortedCorrections.indices, id: \.self) { index in
                                        CorrectionRow(
                                            correction: sortedCorrections[index],
                                            index: index,
                                            isExpanded: expandedItems.contains(index)
                                        ) {
                                            toggleExpansion(for: index)
                                        }
                                    }
                                }
                                .padding(.horizontal, 25)
                            }
                        }
                    }
                }
                .onChange(of: scrollToTop) { _, newValue in
                    if newValue {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                        scrollToTop = false
                    }
                }
            }
            
            // 저장 로딩 화면 오버레이
            if showSaveLoading {
                SaveLoadingView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // 기본 백버튼 숨기기
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    navigationPath.removeLast()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.primaryDark.opacity(0.5))
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveDiary()
                }) {
                    Text(languageManager.currentLanguage.saveButton)
                        .font(.buttonFont)
                        .foregroundColor(.primaryDark)
                }
                .disabled(showSaveLoading)
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
    
    func saveDiary() {
        print("일기 저장 시작...")
        
        // 먼저 스크롤을 맨 위로 이동
        scrollToTop = true
        
        // 스크롤 이동 완료 후 저장 로딩 화면 표시
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 1.0)) {
                showSaveLoading = true
            }
            
            // DataManager를 통해 실제 저장 (정렬된 첨삭 사용)
            dataManager.saveDiary(text: originalText, corrections: sortedCorrections)
            
            // 2초 후 홈 화면으로 이동
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("일기 저장 완료!")
                
                // 홈 화면으로 돌아가기
                navigationPath = NavigationPath()
                
                // 저장 로딩 화면 숨기기
                showSaveLoading = false
            }
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
        VStack(spacing: 8) {
            // 헤더 (항상 보임) - 테두리 추가
            Button(action: onTap) {
                HStack {
                    
                    // 수정 내용 요약
                    Text("\"\(correction.original)\"")
                        .font(.handWrite)
                        .foregroundColor(Color.secondaryRed)
                        .multilineTextAlignment(.leading)
                    
                    
                    Spacer()
                    
                    // 펼치기 아이콘
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(Color.secondaryRed)
                        .font(.buttonFontSmall)
                }
                .padding()
                .background(Color.secondaryRed.opacity(0.2))
                .overlay(
                    Rectangle()
                        .stroke(Color.secondaryRed.opacity(0.6), lineWidth: 1.8)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 상세 내용 (펼쳤을 때만 보임) - 테두리 추가 및 간격 조정
            if isExpanded {
                VStack(alignment: .leading, spacing: 15) {
                    
                    // 수정안
                    Text("→ \"\(correction.corrected)\"")
                        .padding(.horizontal, 5)
                        .font(.bodyFont)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Rectangle()
                        .fill(Color.primaryDark.opacity(0.2))
                        .frame(height: 1.8)
                    
                    // 설명
                    Text(correction.explanation)
                        .padding(.horizontal, 5)
                        .font(.bodyFont)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(17)
                }
                .padding()
                .background(Color.clear)
                .overlay(
                    Rectangle()
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1.8)
                )
            }
        }
        .background(Color.clear)
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

// 하이라이트된 텍스트 컴포넌트
struct HighlightedText: View {
    let originalText: String
    let corrections: [CorrectionItem]
    
    var body: some View {
        Text(attributedString)
            .font(.handWrite) // 전체 텍스트에 handWrite 폰트 적용
            .lineSpacing(17)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
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
                
            }
        }
        
        return result
    }
}
