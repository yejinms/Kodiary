//
//  DiaryDetailView.swift
//  Kodiary
//
//  Created by Niko on 6/20/25.
//

import SwiftUI

struct DiaryDetailView: View {
    @State var diary: DiaryEntry
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    
    @State private var expandedItems: Set<Int> = []
    
    var corrections: [CorrectionItem] {
        dataManager.getCorrections(for: diary)
    }
    
    // 날짜 관련 computed properties - CorrectionResultView와 동일
    var dateComponents: (year: String, month: String, weekday: String) {
        let targetDate = diary.date ?? Date()
        let components = languageManager.currentLanguage.dateComponents
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        
        formatter.dateFormat = components.year
        let year = formatter.string(from: targetDate)
        
        formatter.dateFormat = components.month
        let month = formatter.string(from: targetDate)
        
        formatter.dateFormat = components.weekday
        let weekday = formatter.string(from: targetDate)
        
        return (year, month, weekday)
    }
    
    var dayString: String {
        let targetDate = diary.date ?? Date()
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        formatter.dateFormat = languageManager.currentLanguage.dayDateFormat
        return formatter.string(from: targetDate)
    }
    
    // 이전/다음 일기 찾기
    var previousDiary: DiaryEntry? {
        let sortedDiaries = dataManager.savedDiaries.sorted {
            ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast)
        }
        guard let currentIndex = sortedDiaries.firstIndex(where: { $0.id == diary.id }),
              currentIndex > 0 else { return nil }
        return sortedDiaries[currentIndex - 1]
    }
    
    var nextDiary: DiaryEntry? {
        let sortedDiaries = dataManager.savedDiaries.sorted {
            ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast)
        }
        guard let currentIndex = sortedDiaries.firstIndex(where: { $0.id == diary.id }),
              currentIndex < sortedDiaries.count - 1 else { return nil }
        return sortedDiaries[currentIndex + 1]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer()
                    .frame(height: 16)
                
                // CorrectionResultView와 동일한 날짜 헤더 + 좌우 쉐브론 버튼
                ZStack {
                    // ResponsiveDateHeader와 동일한 구조
                    ZStack {
                        Rectangle()
                            .frame(height: 70)
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
                    .frame(height: 70)
                }
                
                VStack(spacing: 16) {
                    // CorrectionResultView와 동일한 원형 날짜 표시
                    ZStack {
                        // 좌우 쉐브론 버튼 오버레이
                        HStack {
                            // 이전 일기 버튼
                            Button(action: {
                                if let prev = previousDiary {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        diary = prev
                                        expandedItems.removeAll()
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(previousDiary != nil ? .primaryDark : .gray.opacity(0.3))
                                    .padding(.leading, 10)
                            }
                            .disabled(previousDiary == nil)
                            
                            Spacer()
                            
                            // 다음 일기 버튼
                            Button(action: {
                                if let next = nextDiary {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        diary = next
                                        expandedItems.removeAll()
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundColor(nextDiary != nil ? .primaryDark : .gray.opacity(0.3))
                                    .padding(.trailing, 10)
                            }
                            .disabled(nextDiary == nil)
                        }
                        
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
                            Text(dayString)
                                .font(.titleHuge)
                                .foregroundColor(.primaryDark)
                        }
                    }
                    .padding(.top, 10)
                    
                    // 첨삭 완료 상태 표시 (CorrectionResultView와 동일)
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
                            Text(languageManager.currentLanguage.correctionCompleteSubtitle(corrections.count))
                                .font(.buttonFontSmall)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    
                    // 작성된 텍스트 영역 (CorrectionResultView와 동일)
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
                        
                        // 하이라이트된 텍스트
                        ScrollView {
                            HighlightedText(
                                originalText: diary.originalText ?? "내용 없음",
                                corrections: corrections
                            )
                            .font(.handWrite)
                            .lineSpacing(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(15)
                        }
                        .frame(minHeight: 230)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                    }
                    .padding(.horizontal, 25)
                    
                    // 첨삭 결과 섹션 (CorrectionResultView와 동일)
                    VStack(spacing: 16) {
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
                        .padding(.horizontal, 25)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // 기본 백버튼 숨기기
        .toolbar {
            // 커스텀 백버튼 (좌측)
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.primaryDark.opacity(0.5))
                }
            }
        }
        .onAppear {
            dataManager.fetchDiaries()
        }
    }
    
    func toggleExpansion(for index: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedItems.contains(index) {
                expandedItems.remove(index)
            } else {
                expandedItems.insert(index)
            }
        }
    }
    
    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        
        switch languageManager.currentLanguage.locale.identifier {
        case "ko_KR":
            formatter.dateFormat = "yyyy년 M월 d일 E요일"
        case "ja_JP":
            formatter.dateFormat = "yyyy年M月d日 EEEE"
        default:
            formatter.dateFormat = "MMMM d, yyyy EEEE"
        }
        
        return formatter.string(from: date)
    }
    
    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct DiaryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyDiary = DiaryEntry()
        dummyDiary.id = UUID()
        dummyDiary.date = Date()
        dummyDiary.originalText = "오늘은 날씨가 정말 좋았다. 친구들과 공원에서 산책을 했는데 너무 즐거웠다."
        dummyDiary.characterCount = 45
        dummyDiary.correctionCount = 2
        dummyDiary.createdAt = Date()
        dummyDiary.corrections = "[]"
        
        return NavigationView {
            DiaryDetailView(diary: dummyDiary)
                .environmentObject(DataManager.shared)
                .environmentObject(LanguageManager.shared)
        }
    }
}
