//
//  DiaryDetailView.swift
//  Kodiary
//
//  Created by Niko on 6/20/25.
//

import SwiftUI

struct DiaryEditData: Hashable {
    let originalDiary: DiaryEntry
    let originalText: String
    let isEditMode: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(originalText)
        hasher.combine(isEditMode)
    }
}

struct DiaryDetailView: View {
    @State var diary: DiaryEntry
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    
    
    @State private var expandedItems: Set<Int> = []
    @State private var showingEditAlert = false // 수정 불가 알림
    @State private var showingPremiumAlert = false // 프리미엄 유도 알림
    @State private var showingEditLimitAlert = false // 편집 제한 알림
    @EnvironmentObject var userManager: UserManager // 추가
    
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
    
    // 🆕 오늘 작성한 일기인지 확인
    var isTodayDiary: Bool {
        guard let diaryDate = diary.date else { return false }
        return Calendar.current.isDate(diaryDate, inSameDayAs: Date())
    }

    // 🆕 수정 가능한지 확인
    var canEditDiary: Bool {
        return userManager.isPremiumUser && isTodayDiary && userManager.canEdit()
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
                            .lineSpacing(17)
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    handleEditButtonTap()
                }) {
                    Text(languageManager.currentLanguage.editButton)
                        .font(.buttonFont)
                        .foregroundColor(.primaryDark)
                }
            }
        }
        .onAppear {
            dataManager.fetchDiaries()
        }
        .alert(languageManager.currentLanguage.todayOnlyEditTitle, isPresented: $showingEditAlert) {
            Button(languageManager.currentLanguage.confirmButton) { }
        } message: {
            Text(languageManager.currentLanguage.todayOnlyEditMessage)
        }
        .alert(languageManager.currentLanguage.premiumRequiredForEditTitle, isPresented: $showingPremiumAlert) {
            Button(languageManager.currentLanguage.startPremium) {
                // TODO: 프리미엄 구매 화면으로 이동
            }
            Button(languageManager.currentLanguage.laterButton) { }
        } message: {
            Text(languageManager.currentLanguage.premiumRequiredForEditMessage)
        }
        .alert(languageManager.currentLanguage.dailyDiaryLimitTitle, isPresented: $showingEditLimitAlert) {
            Button(languageManager.currentLanguage.confirmButton) { }
        } message: {
            Text(languageManager.currentLanguage.dailyDiaryLimitMessage)
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
    
    func handleEditButtonTap() {
        if !userManager.isPremiumUser {
            // 무료 사용자 - 프리미엄 유도
            showingPremiumAlert = true
        } else if !isTodayDiary {
            // 유료 사용자지만 오늘 일기가 아님
            showingEditAlert = true
        } else if !userManager.canEdit() {
            // 유료 사용자지만 일일 한도 초과
            showingEditLimitAlert = true
        } else {
            // 🆕 수정 가능 - 수정 모드로 DiaryWriteView 이동
            let editData = DiaryEditData(
                originalDiary: diary,
                originalText: diary.originalText ?? "",
                isEditMode: true
            )
            navigationPath.append(editData) // NavigationPath에 직접 추가
        }
    }
}
