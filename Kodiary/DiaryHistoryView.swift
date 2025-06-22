//
//  DiaryHistoryView.swift
//  Kodiary
//
//  Created by Niko on 6/19/25.
//

import SwiftUI

struct DiaryHistoryView: View {
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 캘린더 헤더
            CalendarHeader(currentMonth: $currentMonth)
            
            // 캘린더 그리드 - 실제 데이터 사용
            CalendarGrid(
                currentMonth: currentMonth,
                selectedDate: $selectedDate,
                diaryDates: dataManager.getDiaryDates()
            )
            
            // 선택된 날짜의 일기 정보 - 실제 데이터 사용
            if let diary = dataManager.getDiary(for: selectedDate) {
                DiaryPreview(diary: diary)
                    .padding()
            } else {
                EmptyDateView(date: selectedDate)
                    .padding()
            }
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // 기본 백버튼 숨기기
        .toolbar {
            // 커스텀 백버튼 (좌측)
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
        }
        .onAppear {
            dataManager.fetchDiaries()
        }
    }
}

// 캘린더 헤더 - 다국어 지원 (상하 선 추가)
struct CalendarHeader: View {
    @Binding var currentMonth: Date
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        Spacer()
            .frame(height: 26)
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
            
            HStack {
                // 이전 달 버튼
                Button(action: {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }) {
                    Image(systemName: "chevron.left")
                        .font(.titleLarge)
                        .foregroundColor(.primaryDark)
                }
                
                // 현재 월 표시
                Text(monthYearString(from: currentMonth))
                    .font(.titleLarge)
                    .foregroundColor(.primaryDark)
                    .padding(.horizontal, 20)
                
                // 다음 달 버튼
                Button(action: {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }) {
                    Image(systemName: "chevron.right")
                        .font(.titleLarge)
                        .foregroundColor(.primaryDark)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 70)
    }
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        
        // 언어별 날짜 포맷
        switch languageManager.currentLanguage.locale.identifier {
        case "ko_KR":
            formatter.dateFormat = "yyyy     M월"
        case "ja_JP":
            formatter.dateFormat = "yyyy     M月"
        case "en_US":
            formatter.dateFormat = "yyyy     MMMM"
        default:
            formatter.dateFormat = "MMMM     yyyy"
        }
        
        return formatter.string(from: date)
    }
}

// 캘린더 그리드 - 다국어 지원
struct CalendarGrid: View {
    let currentMonth: Date
    @Binding var selectedDate: Date
    let diaryDates: Set<String>
    @EnvironmentObject var languageManager: LanguageManager
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var body: some View {
        ZStack(alignment: .top){
            //줄노트
            VStack(spacing: 60) {
                ForEach(0..<7, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.primaryDark.opacity(0.4))
                        .frame(height: 1.8)
                }
            }
            .padding(.horizontal, 40)
            
            VStack(spacing: 0) {
                // 요일 헤더
                WeekdayHeader()
                
                // 날짜 그리드
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 22) {
                    ForEach(calendarDays, id: \.self) { date in
                        if let date = date {
                            DayCell(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                hasDiary: hasDiaryForDate(date)
                            ) {
                                selectedDate = date
                            }
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 40)
                        }
                    }
                }
                .padding(.horizontal, 30)
            }
        }
        .padding(.top, 10)
    }
    
    var calendarDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let lastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end) else {
            return []
        }
        
        var dates: [Date?] = []
        var currentDate = firstWeek.start
        
        while currentDate < lastWeek.end {
            if calendar.isDate(currentDate, equalTo: currentMonth, toGranularity: .month) {
                dates.append(currentDate)
            } else {
                dates.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    func hasDiaryForDate(_ date: Date) -> Bool {
        let dateString = dateFormatter.string(from: date)
        return diaryDates.contains(dateString)
    }
}

// 요일 헤더 - 다국어 지원
struct WeekdayHeader: View {
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        HStack {
            ForEach(languageManager.currentLanguage.shortWeekdayNames, id: \.self) { weekday in
                Text(weekday)
                    .font(.buttonFont)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 40)
        .padding(.top, 10)
    }
}

// 날짜 셀
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasDiary: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.bodyFont)
                    .foregroundColor(.primaryDark)
                
                Circle()
                    .fill(hasDiary ? Color.secondaryRed : Color.clear)
                    .frame(width: 12, height: 12)
                    .padding(.top, 4)
            }
            .frame(width: 40, height: 40)
            .background(backgroundColor)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var textColor: Color {
        if !isCurrentMonth {
            return .gray.opacity(0.5)
        } else if isSelected {
            return .white
        } else {
            return .primary
        }
    }
    
    var backgroundColor: Color {
        if isSelected {
            return .primaryDark.opacity(0.1)
        } else if hasDiary {
            return .clear
        } else {
            return .clear
        }
    }
}

// 일기 미리보기 - CorrectionResultView 스타일과 통일성 맞춤
struct DiaryPreview: View {
    let diary: DiaryEntry
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더 - CorrectionResultView의 완료 상태 표시와 유사한 스타일
            HStack(alignment: .bottom) {
                    Text(dateString(from: diary.date ?? Date()))
                        .font(.buttonFontSmall)
                        .foregroundColor(.primaryDark)
                        .background(Color.primaryYellow.opacity(0.3))
                
                Spacer()
                
                // 일기 보기 버튼 - CorrectionRow 스타일과 유사
                NavigationLink(destination: DiaryDetailView(diary: diary)) {
                    HStack(spacing: 4) {
                        Text(languageManager.currentLanguage.correctionCountText(Int(diary.correctionCount)))
                            .font(.buttonFontSmall)
                            .foregroundColor(.secondaryRed)
                        Image(systemName: "chevron.right")
                            .font(.buttonFontSmall)
                            .foregroundColor(.secondaryRed)
                    }
                    .foregroundColor(.primaryDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondaryRed.opacity(0.2))
                    .overlay(
                        Rectangle()
                            .stroke(Color.secondaryRed.opacity(0.6), lineWidth: 1.8)
                    )
                }
            }
            
            // 일기 내용 영역 - CorrectionResultView의 텍스트 영역과 유사한 스타일
            ZStack(alignment: .topLeading) {
                // 배경
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(minHeight: 120)
                
                // 줄 노트처럼 선들 추가 (CorrectionResultView와 동일)
                VStack(spacing: 34) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.primaryDark.opacity(0.4))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 38)
                .padding(.horizontal, 10)
                
                // 일기 텍스트
                Text(diary.originalText ?? "내용 없음")
                    .font(.handWrite)
                    .foregroundColor(.primaryDark)
                    .lineSpacing(10)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(15)
            }
            
        }
        .padding()
        .background(Color.clear)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.4), lineWidth: 1.8)
        )
        .padding(.horizontal, 20)
    }
        
    
    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        
        switch languageManager.currentLanguage.locale.identifier {
        case "ko_KR":
            formatter.dateFormat = "M월 d일 E요일"
        case "ja_JP":
            formatter.dateFormat = "M月d日 EEEE"
        default:
            formatter.dateFormat = "MMM d, EEEE"
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

// 일기 없는 날 - 최신 DiaryPreview 스타일과 통일성 맞춤
struct EmptyDateView: View {
    let date: Date
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더 - DiaryPreview와 동일한 스타일
            HStack(alignment: .bottom) {
                Text(dateString(from: date))
                    .font(.buttonFontSmall)
                    .foregroundColor(.primaryDark)
                    .background(Color.primaryDark.opacity(0.1))
                
                Spacer()
                
                // 오늘인 경우 일기 쓰기 유도 버튼
                if Calendar.current.isDate(date, inSameDayAs: Date()) {
                    HStack(spacing: 4) {
                        Text(languageManager.currentLanguage.todayDiaryPrompt)
                            .font(.buttonFontSmall)
                            .foregroundColor(.primaryDark)
                        Image(systemName: "plus")
                            .font(.buttonFontSmall)
                            .foregroundColor(.primaryDark)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primaryBlue.opacity(0.3))
                    .overlay(
                        Rectangle()
                            .stroke(Color.primaryDark.opacity(0.4), lineWidth: 1.8)
                    )
                } else {
                    // 오늘이 아닌 경우 빈 상태 표시
                    HStack(spacing: 4) {
                        Text("empty")
                            .font(.buttonFontSmall)
                            .foregroundColor(.clear)
                        Image(systemName: "minus")
                            .font(.buttonFontSmall)
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.clear)
                }
            }
            
            // 빈 일기 내용 영역 - DiaryPreview의 텍스트 영역과 유사한 스타일
            ZStack(alignment: .topLeading) {
                // 배경
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(minHeight: 120)
                
                // 줄 노트처럼 선들 추가 (DiaryPreview와 동일)
                VStack(spacing: 34) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.primaryDark.opacity(0.4))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 38)
                .padding(.horizontal, 10)
                
                // 빈 상태 메시지
                VStack(spacing: 8) {
                    Text("📅")
                        .font(.title2)
                    
                    Text(languageManager.currentLanguage.noDiaryMessage)
                        .font(.handWrite)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(15)
            }
        }
        .padding()
        .background(Color.clear)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.4), lineWidth: 1.8)
        )
        .padding(.horizontal, 20)
    }
    
    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        
        switch languageManager.currentLanguage.locale.identifier {
        case "ko_KR":
            formatter.dateFormat = "M월 d일 E요일"
        case "ja_JP":
            formatter.dateFormat = "M月d일 EEEE"
        default:
            formatter.dateFormat = "MMM d, EEEE"
        }
        
        return formatter.string(from: date)
    }
}

struct DiaryHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DiaryHistoryView(navigationPath: .constant(NavigationPath()))
                .environmentObject(DataManager.shared)
                .environmentObject(LanguageManager.shared)
        }
    }
}
