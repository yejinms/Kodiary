//
//  DiaryHistoryView.swift
//  Kodiary
//
//  Created by Niko on 6/19/25.
//

import SwiftUI

// 일기 쓰기 화면으로 이동하기 위한 구조체
struct DiaryWriteDestination: Hashable {
    let id = UUID()
}

struct DiaryHistoryView: View {
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 캘린더 헤더
            CalendarHeader(
                currentMonth: $currentMonth,
                onMonthChanged: { newMonth in
                    // 이번 달인지 확인
                    let today = Date()
                    let calendar = Calendar.current
                    
                    if calendar.isDate(newMonth, equalTo: today, toGranularity: .month) {
                        // 이번 달로 돌아온 경우 오늘 날짜 선택
                        selectedDate = today
                    } else {
                        // 다른 달인 경우 해당 월의 1일 선택
                        if let firstDayOfMonth = calendar.dateInterval(of: .month, for: newMonth)?.start {
                            selectedDate = firstDayOfMonth
                        }
                    }
                }
            )
            
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
                EmptyDateView(date: selectedDate, navigationPath: $navigationPath)
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
        .navigationDestination(for: DiaryWriteDestination.self) { _ in
            DiaryWriteView(navigationPath: $navigationPath)
                .environmentObject(dataManager)
                .environmentObject(languageManager)
        }
    }
}

// 캘린더 헤더 - 월 변경 콜백 추가
struct CalendarHeader: View {
    @Binding var currentMonth: Date
    let onMonthChanged: (Date) -> Void // 월 변경 콜백 추가
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
                    if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
                        currentMonth = newMonth
                        onMonthChanged(newMonth) // 콜백 호출
                    }
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
                    if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
                        currentMonth = newMonth
                        onMonthChanged(newMonth) // 콜백 호출
                    }
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

// 캘린더 그리드 - 다국어 지원 (줄노트 내부 이동, 크기 조정)
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
        VStack(spacing: 0) {
            // 요일 헤더
            WeekdayHeader()
            
            // 날짜 그리드와 줄노트를 함께 배치
            ZStack(alignment: .top) {
                // 줄노트 - 캘린더 그리드 내부로 이동
                VStack(spacing: 60) {
                    ForEach(0..<6, id: \.self) { _ in // 최대 6주까지 고려
                        Rectangle()
                            .fill(Color.primaryDark.opacity(0.4))
                            .frame(height: 1.8)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, -65) // 첫 번째 줄이 첫 번째 날짜 행과 맞도록 조정
                
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
        .frame(height: 420) // 캘린더 영역 높이 확대
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
    
    // 오늘 날짜인지 확인하는 computed property 추가
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.bodyFont)
                    .foregroundColor(.primaryDark)
                
                Circle()
                    .fill(circleColor)
                    .frame(width: 12, height: 12)
                    .padding(.top, 4)
            }
            .frame(width: 40, height: 40)
            .background(backgroundColor.opacity(0.8))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 원형 색상을 결정하는 computed property
    private var circleColor: Color {
        if isToday {
            return .gray  // 오늘 날짜는 회색
        } else if hasDiary {
            return .secondaryTeal  // 일기가 있는 날은 teal
        } else {
            return .primaryDark.opacity(0.2)  // 일기가 없는 날은 연한 회색
        }
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

// 일기 미리보기 - 크기 축소
struct DiaryPreview: View {
    let diary: DiaryEntry
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { // spacing 줄임
            // 헤더
            HStack(alignment: .bottom) {
                Text(dateString(from: diary.date ?? Date()))
                    .font(.buttonFontSmall)
                    .foregroundColor(.primaryDark)
                    .background(Color.primaryYellow.opacity(0.3))
                
                Spacer()
                
                // 일기 보기 버튼
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
            
            // 일기 내용 영역 - 높이 축소
            ZStack(alignment: .topLeading) {
                // 배경
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(minHeight: 80) // 높이 축소 (120 -> 80)
                
                // 줄 노트처럼 선들 추가 - 줄 수 줄임
                VStack(spacing: 34) {
                    ForEach(0..<2, id: \.self) { _ in // 3개 -> 2개로 줄임
                        Rectangle()
                            .fill(Color.primaryDark.opacity(0.4))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 28) // top 패딩 줄임
                .padding(.horizontal, 10)
                
                // 일기 텍스트
                Text(diary.originalText ?? "내용 없음")
                    .font(.handWrite)
                    .foregroundColor(.primaryDark)
                    .lineSpacing(17)
                    .lineLimit(2) // 라인 수 줄임 (3 -> 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12) // 패딩 줄임
            }
        }
        .padding(12) // 전체 패딩 줄임
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
    
    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// 일기 없는 날 - 크기 축소
struct EmptyDateView: View {
    let date: Date
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { // spacing 줄임
            // 헤더
            HStack(alignment: .bottom) {
                Text(dateString(from: date))
                    .font(.buttonFontSmall)
                    .foregroundColor(.primaryDark)
                    .background(Color.primaryDark.opacity(0.1))
                
                Spacer()
                
                // 오늘인 경우 일기 쓰기 유도 버튼
                if Calendar.current.isDate(date, inSameDayAs: Date()) {
                    Button(action: {
                        navigationPath.append(DiaryWriteDestination())
                    }) {
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
                    }
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
            
            // 빈 일기 내용 영역 - 높이 축소
            ZStack(alignment: .topLeading) {
                // 배경
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(minHeight: 80) // 높이 축소 (120 -> 80)
                
                // 줄 노트처럼 선들 추가 - 줄 수 줄임
                VStack(spacing: 34) {
                    ForEach(0..<2, id: \.self) { _ in // 3개 -> 2개로 줄임
                        Rectangle()
                            .fill(Color.primaryDark.opacity(0.2))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 28) // top 패딩 줄임
                .padding(.horizontal, 10)
                
                // 빈 상태 메시지
                VStack(spacing: 6) { // spacing 줄임
                    Text("📅")
                        .font(.title3) // 폰트 크기 줄임
                    
                    Text(languageManager.currentLanguage.noDiaryMessage)
                        .font(.handWrite)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(12) // 패딩 줄임
            }
        }
        .padding(12) // 전체 패딩 줄임
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
