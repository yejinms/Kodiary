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
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager  // 추가
    
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
        .navigationTitle(languageManager.currentLanguage.diaryHistoryTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            dataManager.fetchDiaries()
        }
    }
}

// 캘린더 헤더 - 다국어 지원
struct CalendarHeader: View {
    @Binding var currentMonth: Date
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        HStack {
            // 이전 달 버튼
            Button(action: {
                currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // 현재 월 표시
            Text(monthYearString(from: currentMonth))
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            // 다음 달 버튼
            Button(action: {
                currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        
        // 언어별 날짜 포맷
        switch languageManager.currentLanguage.locale.identifier {
        case "ko_KR":
            formatter.dateFormat = "yyyy년 M월"
        case "ja_JP":
            formatter.dateFormat = "yyyy年M月"
        default:
            formatter.dateFormat = "MMMM yyyy"
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
        VStack(spacing: 0) {
            // 요일 헤더
            WeekdayHeader()
            
            // 날짜 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
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
            .padding(.horizontal)
        }
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
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// 날짜 셀 (변경 없음)
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
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(textColor)
                
                Circle()
                    .fill(hasDiary ? Color.blue : Color.clear)
                    .frame(width: 6, height: 6)
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
            return .blue
        } else if hasDiary {
            return .blue.opacity(0.1)
        } else {
            return .clear
        }
    }
}

// 일기 미리보기 - 다국어 지원
struct DiaryPreview: View {
    let diary: DiaryEntry
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📝")
                    .font(.title2)
                Text(dateString(from: diary.date ?? Date()))
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink(destination: DiaryDetailView(diary: diary)) {
                    Text(languageManager.currentLanguage.viewDiaryButton)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Text(diary.originalText ?? "내용 없음")
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(3)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // 통계 정보
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text(languageManager.currentLanguage.correctionCountText(Int(diary.correctionCount)))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "textformat.123")
                        .foregroundColor(.gray)
                        .font(.caption)
                    Text(languageManager.currentLanguage.characterCountText(Int(diary.characterCount)))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(timeString(from: diary.createdAt ?? Date()))
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
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

// 일기 없는 날 - 다국어 지원
struct EmptyDateView: View {
    let date: Date
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("📅")
                    .font(.title2)
                Text(dateString(from: date))
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            Text(languageManager.currentLanguage.noDiaryMessage)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // 일기 쓰기 유도 버튼
            if Calendar.current.isDate(date, inSameDayAs: Date()) {
                Text(languageManager.currentLanguage.todayDiaryPrompt)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.gray.opacity(0.1), radius: 2, x: 0, y: 1)
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
}

struct DiaryHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DiaryHistoryView()
                .environmentObject(DataManager.shared)
                .environmentObject(LanguageManager.shared)
        }
    }
}
