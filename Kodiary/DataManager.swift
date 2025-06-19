import Foundation
import CoreData

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var savedDiaries: [DiaryEntry] = []
    
    // Core Data 컨테이너
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Kodiary")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data 에러: \(error)")
            }
        }
        return container
    }()
    
    // Context
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {
        fetchDiaries()
    }
    
    // MARK: - 일기 저장
    func saveDiary(text: String, corrections: [CorrectionItem]) {
        let newDiary = DiaryEntry(context: context)
        newDiary.id = UUID()
        newDiary.date = Date()
        newDiary.originalText = text
        newDiary.characterCount = Int16(text.count)
        newDiary.correctionCount = Int16(corrections.count)
        newDiary.createdAt = Date()
        
        // 첨삭 데이터를 JSON으로 저장
        do {
            let correctionsData = try JSONEncoder().encode(corrections)
            if let correctionsString = String(data: correctionsData, encoding: .utf8) {
                newDiary.corrections = correctionsString  // 이제 에러 없음
                print("✅ 첨삭 데이터 저장 완료: \(corrections.count)개")
            }
        } catch {
            print("❌ 첨삭 데이터 인코딩 에러: \(error)")
            newDiary.corrections = "[]" // 빈 배열로 저장
        }
        
        saveContext()
        fetchDiaries()
        
        print("✅ 일기 저장 완료: \(text.prefix(20))...")
    }
    
    // MARK: - 저장된 첨삭 데이터 가져오기
    func getCorrections(for diary: DiaryEntry) -> [CorrectionItem] {
        guard let correctionsString = diary.corrections,
              let data = correctionsString.data(using: .utf8) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([CorrectionItem].self, from: data)
        } catch {
            print("첨삭 데이터 디코딩 에러: \(error)")
            return []
        }
    }
    
    // MARK: - 일기 목록 가져오기
    func fetchDiaries() {
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DiaryEntry.date, ascending: false)]
        
        do {
            savedDiaries = try context.fetch(request)
            print("📚 일기 \(savedDiaries.count)개 로드됨")
        } catch {
            print("일기 로드 에러: \(error)")
        }
    }
    
    // MARK: - 특정 날짜의 일기 가져오기
    func getDiary(for date: Date) -> DiaryEntry? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let diaries = try context.fetch(request)
            return diaries.first
        } catch {
            print("특정 날짜 일기 로드 에러: \(error)")
            return nil
        }
    }
    
    // MARK: - 일기 있는 날짜들 가져오기
    func getDiaryDates() -> Set<String> {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return Set(savedDiaries.compactMap { diary in
            guard let date = diary.date else { return nil }
            return dateFormatter.string(from: date)
        })
    }
    
    // MARK: - Context 저장
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("저장 에러: \(error)")
        }
    }
    
    // MARK: - 일기 삭제
    func deleteDiary(_ diary: DiaryEntry) {
        context.delete(diary)
        saveContext()
        fetchDiaries()
    }
    
    // MARK: - 통계
    func getTotalDiariesCount() -> Int {
        return savedDiaries.count
    }
    
    func getDiariesCount(for month: Date) -> Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month
        
        return savedDiaries.filter { diary in
            guard let date = diary.date else { return false }
            return date >= startOfMonth && date < endOfMonth
        }.count
    }
}

