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
    @EnvironmentObject var dataManager: DataManager  // 실제 데이터 연결
    
    var body: some View {
        VStack(spacing: 0) {
            // 캘린더 헤더
            CalendarHeader(currentMonth: $currentMonth)
            
            // 캘린더 그리드 - 실제 데이터 사용
            CalendarGrid(
                currentMonth: currentMonth,
                selectedDate: $selectedDate,
                diaryDates: dataManager.getDiaryDates()  // 실제 저장된 날짜들
            )
            
            // 선택된 날짜의 일기 정보 - 실제 데이터 사용
            if let diary = dataManager.getDiary(for: selectedDate) {
                DiaryPreview(diary: diary)  // 실제 일기 데이터
                    .padding()
            } else {
                EmptyDateView(date: selectedDate)
                    .padding()
            }
            
            Spacer()
        }
        .navigationTitle("일기 히스토리")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 화면이 나타날 때 데이터 새로고침
            dataManager.fetchDiaries()
        }
    }
}

// 캘린더 헤더 (동일)
struct CalendarHeader: View {
    @Binding var currentMonth: Date
    
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
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: date)
    }
}

// 캘린더 그리드 (동일)
struct CalendarGrid: View {
    let currentMonth: Date
    @Binding var selectedDate: Date
    let diaryDates: Set<String>  // 실제 데이터 받음
    
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
                        // 빈 셀
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // 캘린더에 표시할 날짜들 계산
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
                dates.append(nil) // 다른 달의 날짜는 nil
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

// 요일 헤더 (동일)
struct WeekdayHeader: View {
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        HStack {
            ForEach(weekdays, id: \.self) { weekday in
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

// 날짜 셀 (동일)
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasDiary: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // 날짜 숫자
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(textColor)
                
                // 일기 존재 표시 점
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

// 일기 미리보기 - 실제 데이터 사용
struct DiaryPreview: View {
    let diary: DiaryEntry  // 실제 일기 데이터
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📝")
                    .font(.title2)
                Text(dateString(from: diary.date ?? Date()))
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button("보기") {
                    // 나중에 일기 상세보기로 이동
                    print("일기 상세보기: \(diary.originalText ?? "")")
                    let corrections = dataManager.getCorrections(for: diary)
                    print("첨삭 내용: \(corrections.count)개")
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // 실제 일기 내용 미리보기
            Text(diary.originalText ?? "내용 없음")
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(3)  // 3줄까지 표시
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // 통계 정보
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("첨삭 \(diary.correctionCount)개")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "textformat.123")
                        .foregroundColor(.gray)
                        .font(.caption)
                    Text("\(diary.characterCount)자")
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
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: date)
    }
    
    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// 일기 없는 날 (동일)
struct EmptyDateView: View {
    let date: Date
    
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
            
            Text("이 날에는 일기를 쓰지 않았어요")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // 일기 쓰기 유도 버튼
            if Calendar.current.isDate(date, inSameDayAs: Date()) {
                Text("오늘 일기를 써보세요! ✍️")
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
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: date)
    }
}

struct DiaryHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DiaryHistoryView()
                .environmentObject(DataManager.shared)  // 프리뷰에도 데이터 매니저 추가
        }
    }
}
