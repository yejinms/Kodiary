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
    @EnvironmentObject var languageManager: LanguageManager  // 추가
    
    @State private var expandedItems: Set<Int> = []
    
    var corrections: [CorrectionItem] {
        dataManager.getCorrections(for: diary)
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
            VStack(spacing: 20) {
                // 날짜 헤더 (이전/다음 버튼 포함)
                VStack(spacing: 10) {
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
                                .foregroundColor(previousDiary != nil ? .blue : .gray)
                        }
                        .disabled(previousDiary == nil)
                        
                        Spacer()
                        
                        // 현재 일기 날짜
                        VStack(spacing: 4) {
                            Text(dateString(from: diary.date ?? Date()))
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(timeString(from: diary.createdAt ?? Date()))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
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
                                .foregroundColor(nextDiary != nil ? .blue : .gray)
                        }
                        .disabled(nextDiary == nil)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // 원본 일기 표시
                VStack(alignment: .leading, spacing: 10) {
                    Text(languageManager.currentLanguage.writtenDiaryTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    // 하이라이트된 텍스트 표시
                    HighlightedText(
                        originalText: diary.originalText ?? "내용 없음",
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
        .navigationTitle(languageManager.currentLanguage.diaryDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
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
