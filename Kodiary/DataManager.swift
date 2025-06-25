import Foundation
import CoreData
import CloudKit

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var savedDiaries: [DiaryEntry] = []
    @Published var isCloudKitAvailable = false
    @Published var syncStatus = "확인 중..."
    @Published var isInitialSyncComplete = false
    
    // 초기화 상태 추적
    private var isInitialized = false
    private var isObservingNotifications = false
    private var lastSyncTime = Date.distantPast
    private let minSyncInterval: TimeInterval = 2.0
    
    // 싱글톤 보장을 위한 lazy 초기화
    private var _persistentContainer: NSPersistentCloudKitContainer?
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        // 이미 초기화된 경우 기존 인스턴스 반환
        if let existing = _persistentContainer {
            print("♻️ 기존 CloudKit 컨테이너 재사용")
            return existing
        }
        
        print("🔄 새 CloudKit 컨테이너 생성 중...")
        
        let container = NSPersistentCloudKitContainer(name: "Kodiary")
        
        // 스토어 설정을 한 번만 설정
        guard let storeDescription = container.persistentStoreDescriptions.first else {
            fatalError("❌ 스토어 설명을 찾을 수 없습니다")
        }
        
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.Kodiary"
        )
        
        container.loadPersistentStores { [weak self] storeDescription, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ CloudKit Core Data 로드 실패: \(error)")
                    self?.syncStatus = "동기화 사용 불가"
                    self?.isCloudKitAvailable = false
                } else {
                    print("✅ CloudKit Core Data 연동 성공!")
                    self?.syncStatus = "동기화 준비됨"
                    self?.isCloudKitAvailable = true
                    
                    container.viewContext.automaticallyMergesChangesFromParent = true
                    
                    // 한 번만 초기화
                    if self?.isInitialized == false {
                        self?.isInitialized = true
                        self?.setupNotificationObservers()
                        
                        // 1초 후 초기 동기화
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self?.performInitialCloudKitSync()
                        }
                    }
                }
            }
        }
        
        // 인스턴스 저장
        _persistentContainer = container
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {
        print("🏗️ DataManager 싱글톤 초기화")
        checkCloudKitAccount()
    }
    
    // MARK: - 알림 관찰자 설정 (중복 방지)
    private func setupNotificationObservers() {
        guard !isObservingNotifications else {
            print("⚠️ 이미 알림 관찰자가 등록됨 - 중복 등록 방지")
            return
        }
        
        isObservingNotifications = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: persistentContainer.persistentStoreCoordinator
        )
        
        print("✅ CloudKit 알림 관찰자 등록 완료")
    }
    
    @objc private func storeRemoteChange(_ notification: Notification) {
        let now = Date()
        
        guard now.timeIntervalSince(lastSyncTime) > minSyncInterval else {
            print("⏸️ CloudKit 변경 감지 - 너무 빈번함, 건너뛰기")
            return
        }
        
        lastSyncTime = now
        print("🔄 CloudKit 원격 변경 감지 - 데이터 새로고침")
        
        DispatchQueue.main.async {
            self.fetchDiariesSilently()
        }
    }
    
    // MARK: - 메인 스레드 보장 데이터 새로고침
    private func fetchDiariesSilently() {
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DiaryEntry.date, ascending: false)]
        
        do {
            let newDiaries = try context.fetch(request)
            
            if newDiaries.count != savedDiaries.count ||
               !areArraysEqual(newDiaries, savedDiaries) {
                
                // 메인 스레드에서 UI 업데이트 보장
                DispatchQueue.main.async {
                    self.savedDiaries = newDiaries
                    print("📚 일기 데이터 업데이트됨: \(self.savedDiaries.count)개")
                }
            }
        } catch {
            print("❌ 조용한 일기 로드 에러: \(error)")
        }
    }
    
    // MARK: - 초기 CloudKit 동기화
    private func performInitialCloudKitSync() {
        guard isCloudKitAvailable else { return }
        
        print("🔄 초기 CloudKit 동기화 시작...")
        
        // 즉시 일기 데이터 로드
        fetchDiaries()
        
        // 1초 후 강제 새로고침 (CloudKit에서 최신 데이터 가져오기)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.forceRefreshFromCloudKit()
            
            // 추가로 2초 후 다시 한 번 새로고침
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.fetchDiaries()
                self.isInitialSyncComplete = true
                print("✅ 초기 CloudKit 동기화 완료")
            }
        }
    }

    // MARK: - 앱 시작 시 즉시 새로고침 메서드 추가
    func refreshDataOnAppStart() {
        print("🔄 앱 시작 시 데이터 새로고침")
        
        // 즉시 한 번 로드
        fetchDiaries()
        
        // 0.5초 후 한 번 더 (CloudKit 동기화 대기)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.fetchDiaries()
        }
        
        // 2초 후 강제 새로고침
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.forceRefreshFromCloudKit()
        }
    }
    
    // MARK: - 공개 메서드들 (메인 스레드 보장)
    func checkCloudKitAccount() {
        let container = CKContainer(identifier: "iCloud.Kodiary")
        
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch status {
                case .available:
                    self.syncStatus = "iCloud 동기화 사용 가능"
                    self.isCloudKitAvailable = true
                case .noAccount:
                    self.syncStatus = "iCloud 계정이 없습니다"
                    self.isCloudKitAvailable = false
                case .restricted:
                    self.syncStatus = "iCloud 사용 제한됨"
                    self.isCloudKitAvailable = false
                case .couldNotDetermine:
                    self.syncStatus = "iCloud 상태 확인 불가"
                    self.isCloudKitAvailable = false
                case .temporarilyUnavailable:
                    self.syncStatus = "iCloud 일시적으로 사용 불가"
                    self.isCloudKitAvailable = false
                @unknown default:
                    self.syncStatus = "알 수 없는 상태"
                    self.isCloudKitAvailable = false
                }
                print("📱 CloudKit 상태: \(self.syncStatus)")
            }
        }
    }
    
    func saveDiary(text: String, corrections: [CorrectionItem]) {
        let newDiary = DiaryEntry(context: context)
        newDiary.id = UUID()
        newDiary.date = Date()
        newDiary.originalText = text
        newDiary.characterCount = Int16(text.count)
        newDiary.correctionCount = Int16(corrections.count)
        newDiary.createdAt = Date()
        
        do {
            let correctionsData = try JSONEncoder().encode(corrections)
            if let correctionsString = String(data: correctionsData, encoding: .utf8) {
                newDiary.corrections = correctionsString
            }
        } catch {
            print("❌ 첨삭 데이터 인코딩 에러: \(error)")
            newDiary.corrections = "[]"
        }
        
        saveContext()
        
        DispatchQueue.main.async {
            self.fetchDiaries()
        }
        
        print("✅ 일기 저장 완료 + CloudKit 동기화!")
    }
    
    private func saveContext() {
        context.performAndWait {
            do {
                try context.save()
                print("💾 Core Data 저장 (CloudKit 자동 업로드)")
            } catch {
                print("❌ 저장 에러: \(error)")
            }
        }
    }
    
    func fetchDiaries() {
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DiaryEntry.date, ascending: false)]
        
        context.performAndWait {
            do {
                let newDiaries = try context.fetch(request)
                
                DispatchQueue.main.async {
                    if newDiaries.count != self.savedDiaries.count ||
                       !self.areArraysEqual(newDiaries, self.savedDiaries) {
                        self.savedDiaries = newDiaries
                        print("📚 일기 \(self.savedDiaries.count)개 로드됨 (CloudKit 동기화됨)")
                    }
                }
            } catch {
                print("❌ 일기 로드 에러: \(error)")
            }
        }
    }
    
    func forceRefreshFromCloudKit() {
        guard isCloudKitAvailable else {
            print("⚠️ CloudKit 사용 불가능")
            return
        }
        
        print("🔄 CloudKit에서 강제 데이터 새로고침 시작")
        
        context.performAndWait {
            context.refreshAllObjects()
        }
        
        fetchDiaries()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isInitialSyncComplete = true
            print("✅ CloudKit 강제 새로고침 완료")
        }
    }
    
    // MARK: - 기존 메서드들 (변경 없음)
    private func areArraysEqual(_ array1: [DiaryEntry], _ array2: [DiaryEntry]) -> Bool {
        guard array1.count == array2.count else { return false }
        
        for (diary1, diary2) in zip(array1, array2) {
            if diary1.id != diary2.id ||
               diary1.originalText != diary2.originalText ||
               diary1.date != diary2.date {
                return false
            }
        }
        return true
    }
    
    func getCorrections(for diary: DiaryEntry) -> [CorrectionItem] {
        guard let correctionsString = diary.corrections,
              let data = correctionsString.data(using: .utf8) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([CorrectionItem].self, from: data)
        } catch {
            print("❌ 첨삭 데이터 디코딩 에러: \(error)")
            return []
        }
    }
    
    func getDiary(for date: Date) -> DiaryEntry? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        var result: DiaryEntry?
        context.performAndWait {
            do {
                let diaries = try context.fetch(request)
                result = diaries.first
            } catch {
                print("특정 날짜 일기 로드 에러: \(error)")
            }
        }
        return result
    }
    
    func deleteDiary(_ diary: DiaryEntry) {
        context.performAndWait {
            context.delete(diary)
        }
        saveContext()
        
        DispatchQueue.main.async {
            self.fetchDiaries()
        }
    }
    
    func getDiaryDates() -> Set<String> {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return Set(savedDiaries.compactMap { diary in
            guard let date = diary.date else { return nil }
            return dateFormatter.string(from: date)
        })
    }
    
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("🗑️ DataManager 정리됨")
    }
}
