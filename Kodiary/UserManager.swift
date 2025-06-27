import Foundation
import AuthenticationServices
import SwiftUI
import CoreData
import CloudKit

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var isLoggedIn = false
    @Published var userName = ""
    @Published var userEmail = ""
    @Published var isLoading = false
    @Published var needsNameSetup = false
    @Published var needsLanguageSetup = false
    @Published var isSettingsLoaded = false
    @Published var isPremiumUser = false
    @Published var dailyEditCount = 0
    @Published var lastEditDate: Date?
    
    // UserDefaults 키들
    private let isLoggedInKey = "is_logged_in"
    private let userNameKey = "user_name"
    private let userEmailKey = "user_email"
    private let userIdKey = "user_id"
    private let isPremiumUserKey = "is_premium_user"
    private let dailyEditCountKey = "daily_edit_count"
    private let lastEditDateKey = "last_edit_date"
    
    private init() {
        loadUserData()
    }
    
    // MARK: - 저장된 사용자 데이터 로드 (수정됨)
    private func loadUserData() {
        isLoggedIn = UserDefaults.standard.bool(forKey: isLoggedInKey)
        userName = UserDefaults.standard.string(forKey: userNameKey) ?? ""
        userEmail = UserDefaults.standard.string(forKey: userEmailKey) ?? ""
        
        // 🆕 멤버십 데이터 로드
        isPremiumUser = UserDefaults.standard.bool(forKey: isPremiumUserKey)
        dailyEditCount = UserDefaults.standard.integer(forKey: dailyEditCountKey)
        if let lastEditDateData = UserDefaults.standard.object(forKey: lastEditDateKey) as? Date {
            lastEditDate = lastEditDateData
        }
        
        // 🆕 CloudKit 복원 후 상세 로그 추가
        print("📊 CloudKit 복원 완료:")
        print("  - 첨삭횟수: \(dailyEditCount)")
        print("  - 마지막날짜: \(lastEditDate?.description ?? "없음")")
        print("  - 오늘날짜: \(Date())")

        // 날짜 변경 시 카운트 리셋 체크 (단, 복원된 데이터 보호)
        checkAndResetDailyEditCount()

        print("📊 날짜 체크 후:")
        print("  - 첨삭횟수: \(dailyEditCount)")
        print("  - 마지막날짜: \(lastEditDate?.description ?? "없음")")
        
        // 이미 로그인된 상태면 설정도 로드된 것으로 처리
        if isLoggedIn {
            isSettingsLoaded = true
            print("🔐 기존 로그인 상태 - 설정 로드 완료로 처리")
        }
        
        print("🔐 사용자 데이터 로드됨 - 로그인: \(isLoggedIn), 이름: \(userName), 프리미엄: \(isPremiumUser)")
    }
    
    // 🆕 일일 첨삭 카운트 리셋 확인
    private func checkAndResetDailyEditCount() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastEdit = lastEditDate {
            let lastEditDay = Calendar.current.startOfDay(for: lastEdit)
            
            if lastEditDay < today {
                // 실제로 날짜가 바뀌었을 때만 리셋
                print("🔄 날짜 변경 감지: \(lastEditDay) → \(today)")
                dailyEditCount = 0
                lastEditDate = nil
                saveDailyEditData()
                print("🔄 일일 첨삭 카운트 리셋됨 (날짜 변경)")
            } else if lastEditDay == today {
                // 오늘 날짜면 유지
                print("✅ 오늘 첨삭 횟수 유지: \(dailyEditCount)/3")
            }
        } else {
            // lastEditDate가 없지만 dailyEditCount가 0이 아닌 경우
            if dailyEditCount > 0 {
                // 오늘 첨삭한 것으로 간주하고 날짜 설정
                lastEditDate = today
                print("📅 마지막 첨삭 날짜 복원: 오늘로 설정 (\(dailyEditCount)/3)")
            }
        }
    }
    
    // 🆕 첨삭 시도 가능한지 확인
    func canEdit() -> Bool {
        checkAndResetDailyEditCount()
        
        if !isPremiumUser {
            return false // 무료 사용자는 편집 불가
        }
        
        return dailyEditCount < 3 // 프리미엄 사용자는 하루 3회까지
    }
    
    // 🆕 첨삭 횟수 증가
    func incrementEditCount() {
        // 🆕 무료/유료 구분 없이 모든 사용자에게 적용
        dailyEditCount += 1
        lastEditDate = Date()
        saveDailyEditData()
        
        print("📝 첨삭 횟수 증가: \(dailyEditCount)/3 (사용자: \(isPremiumUser ? "프리미엄" : "무료"))")
    }
    
    // 🆕 일일 첨삭 데이터 저장
    private func saveDailyEditData() {
        UserDefaults.standard.set(dailyEditCount, forKey: dailyEditCountKey)
        UserDefaults.standard.set(lastEditDate, forKey: lastEditDateKey)
        
        print("💾 로컬 저장 완료: \(dailyEditCount)/3")
        
        // CloudKit에도 즉시 저장
        if isLoggedIn {
            print("☁️ CloudKit 동기화 시작...")
            
            // 🆕 즉시 동기화 (비동기가 아닌 Task로 즉시 실행)
            Task {
                await syncDailyEditDataToCloudKit()
            }
        }
    }
    
    // 🆕 CloudKit에 일일 첨삭 데이터 동기화
    private func syncDailyEditDataToCloudKit() {
        guard let currentUserID = UserDefaults.standard.string(forKey: userIdKey) else { return }
        
        Task {
            await saveDailyEditDataToCloudKit(
                appleUserID: currentUserID,
                dailyEditCount: dailyEditCount,
                lastEditDate: lastEditDate
            )
        }
    }
    
    // 🆕 CloudKit에 일일 첨삭 데이터 저장
    private func saveDailyEditDataToCloudKit(
        appleUserID: String,
        dailyEditCount: Int,
        lastEditDate: Date?
    ) async {
        print("☁️ CloudKit 첨삭 데이터 저장 시작:")
        print("  - 사용자ID: \(appleUserID)")
        print("  - 저장할 첨삭횟수: \(dailyEditCount)")
        print("  - 저장할 마지막날짜: \(lastEditDate?.description ?? "없음")")
        
        let container = CKContainer(identifier: "iCloud.Kodiary")
        let database = container.privateCloudDatabase
        
        do {
            // 🆕 최대 3번 재시도
            var retryCount = 0
            let maxRetries = 3
            
            while retryCount < maxRetries {
                do {
                    // 매번 최신 레코드 다시 가져오기
                    var existingRecord: CKRecord? = nil
                    let possibleRecordTypes = ["CD_UserSettings", "UserSettings", "CDUserSettings"]
                    
                    for recordType in possibleRecordTypes {
                        let predicates = [
                            NSPredicate(format: "CD_appleUserID == %@", appleUserID),
                            NSPredicate(format: "appleUserID == %@", appleUserID)
                        ]
                        
                        for predicate in predicates {
                            let query = CKQuery(recordType: recordType, predicate: predicate)
                            
                            do {
                                let (matchResults, _) = try await database.records(matching: query)
                                
                                for (_, result) in matchResults {
                                    switch result {
                                    case .success(let record):
                                        existingRecord = record
                                        print("✅ 최신 CloudKit 레코드 발견: \(recordType) (시도: \(retryCount + 1))")
                                        break
                                    case .failure:
                                        break
                                    }
                                }
                                
                                if existingRecord != nil {
                                    break
                                }
                            } catch {
                                continue
                            }
                        }
                        
                        if existingRecord != nil {
                            break
                        }
                    }
                    
                    if let record = existingRecord {
                        // 저장 전 현재 값 확인
                        print("☁️ 저장 전 CloudKit 값 (시도: \(retryCount + 1)):")
                        print("  - 기존 첨삭횟수: \(record["CD_dailyEditCount"] ?? "없음")")
                        print("  - 기존 마지막날짜: \(record["CD_lastEditDate"] ?? "없음")")
                        
                        // 일일 첨삭 데이터 업데이트
                        record["CD_dailyEditCount"] = dailyEditCount
                        record["dailyEditCount"] = dailyEditCount
                        record["CD_lastEditDate"] = lastEditDate
                        record["lastEditDate"] = lastEditDate
                        record["CD_modifiedAt"] = Date()
                        record["modifiedAt"] = Date()
                        
                        print("☁️ 새 값으로 설정 완료:")
                        print("  - 새 첨삭횟수: \(dailyEditCount)")
                        print("  - 새 마지막날짜: \(lastEditDate?.description ?? "없음")")
                        
                        // CloudKit에 저장
                        let savedRecord = try await database.save(record)
                        
                        print("☁️ CloudKit 저장 성공! (시도: \(retryCount + 1))")
                        print("  - 저장된 첨삭횟수: \(savedRecord["CD_dailyEditCount"] ?? "없음")")
                        print("  - 저장된 마지막날짜: \(savedRecord["CD_lastEditDate"] ?? "없음")")
                        
                        return // 성공하면 종료
                        
                    } else {
                        print("❌ CloudKit 사용자 설정 레코드를 찾을 수 없음 (시도: \(retryCount + 1))")
                        return
                    }
                    
                } catch let error as CKError {
                    if error.code == .serverRecordChanged {
                        // 🆕 충돌 발생 시 재시도
                        retryCount += 1
                        print("⚠️ CloudKit 충돌 발생, 재시도 중... (\(retryCount)/\(maxRetries))")
                        
                        if retryCount < maxRetries {
                            // 짧은 지연 후 재시도
                            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초
                            continue
                        } else {
                            print("❌ CloudKit 최대 재시도 횟수 초과")
                            throw error
                        }
                    } else {
                        throw error
                    }
                }
            }
            
        } catch {
            print("❌ CloudKit 일일 첨삭 데이터 동기화 실패: \(error)")
        }
    }
    
    // 🆕 프리미엄 사용자 설정
    func setPremiumUser(_ isPremium: Bool) {
        DispatchQueue.main.async {
            self.isPremiumUser = isPremium
            UserDefaults.standard.set(isPremium, forKey: self.isPremiumUserKey)
            print("💎 프리미엄 상태 변경: \(isPremium)")
        }
        
        // CloudKit에도 저장
        if isLoggedIn {
            guard let currentUserID = UserDefaults.standard.string(forKey: userIdKey) else { return }
            
            Task {
                await self.savePremiumStatusToCloudKit(
                    appleUserID: currentUserID,
                    isPremium: isPremium
                )
            }
        }
    }
    
    // 🆕 CloudKit에 프리미엄 상태 저장
    private func savePremiumStatusToCloudKit(
        appleUserID: String,
        isPremium: Bool
    ) async {
        print("☁️ CloudKit 프리미엄 상태 저장 시작:")
        print("  - 사용자ID: \(appleUserID)")
        print("  - 저장할 프리미엄 상태: \(isPremium)")
        
        let container = CKContainer(identifier: "iCloud.Kodiary")
        let database = container.privateCloudDatabase
        
        do {
            // 기존 사용자 설정 레코드 찾기
            let possibleRecordTypes = ["CD_UserSettings", "UserSettings", "CDUserSettings"]
            var existingRecord: CKRecord? = nil
            
            for recordType in possibleRecordTypes {
                // 🆕 OR 대신 각 필드별로 따로 검색
                let predicates = [
                    NSPredicate(format: "CD_appleUserID == %@", appleUserID),
                    NSPredicate(format: "appleUserID == %@", appleUserID)
                ]
                
                for predicate in predicates {
                    let query = CKQuery(recordType: recordType, predicate: predicate)
                    
                    do {
                        let (matchResults, _) = try await database.records(matching: query)
                        
                        for (_, result) in matchResults {
                            switch result {
                            case .success(let record):
                                existingRecord = record
                                print("✅ 기존 CloudKit 레코드 발견: \(recordType)")
                                break
                            case .failure:
                                break
                            }
                        }
                        
                        if existingRecord != nil {
                            break
                        }
                    } catch {
                        print("❌ CloudKit 레코드 검색 실패 (\(recordType), \(predicate)): \(error)")
                        continue
                    }
                }
                
                if existingRecord != nil {
                    break
                }
            }
            
            if let record = existingRecord {
                // 저장 전 현재 값 확인
                print("☁️ 저장 전 CloudKit 프리미엄 상태:")
                print("  - 기존 프리미엄: \(record["CD_isPremiumUser"] ?? "없음")")
                
                // 프리미엄 상태 업데이트
                record["CD_isPremiumUser"] = isPremium
                record["isPremiumUser"] = isPremium
                record["CD_modifiedAt"] = Date()
                record["modifiedAt"] = Date()
                
                print("☁️ 새 프리미엄 상태로 설정 완료: \(isPremium)")
                
                // CloudKit에 저장
                let savedRecord = try await database.save(record)
                
                print("☁️ CloudKit 프리미엄 상태 저장 성공!")
                print("  - 저장된 프리미엄 상태: \(savedRecord["CD_isPremiumUser"] ?? "없음")")
                
            } else {
                print("❌ CloudKit 사용자 설정 레코드를 찾을 수 없음")
            }
            
        } catch {
            print("❌ CloudKit 프리미엄 상태 동기화 실패: \(error)")
        }
    }
    
    // MARK: - 기존 메서드들 수정
    
    // loadSettingsFromCloudKitRecord 메서드에 추가
    private func loadSettingsFromCloudKitRecord(_ record: CKRecord) {
        print("👤 기존 사용자 설정 CloudKit에서 직접 로드")
        print("📄 레코드의 모든 키: \(record.allKeys())")
        
        // 여러 가능한 필드명으로 시도
        let userNameFields = ["CD_userName", "userName", "CDuserName"]
        let correctionLanguageFields = ["CD_correctionLanguageCode", "correctionLanguageCode", "CDcorrectionLanguageCode"]
        let nativeLanguageFields = ["CD_nativeLanguageCode", "nativeLanguageCode", "CDnativeLanguageCode"]
        let premiumFields = ["CD_isPremiumUser", "isPremiumUser", "CDisPremiumUser"]
        let dailyEditCountFields = ["CD_dailyEditCount", "dailyEditCount", "CDdailyEditCount"]
        let lastEditDateFields = ["CD_lastEditDate", "lastEditDate", "CDlastEditDate"]
        
        // 🆕 일일 첨삭 횟수 복원
        for field in dailyEditCountFields {
            if let editCount = record[field] as? Int {
                print("📊 CloudKit에서 첨삭 횟수 발견:")
                print("  - 필드명: \(field)")
                print("  - 값: \(editCount)")
                
                self.dailyEditCount = editCount
                UserDefaults.standard.set(editCount, forKey: dailyEditCountKey)
                print("📝 일일 첨삭 횟수 복원: \(editCount) (필드: \(field))")
                break
            }
        }

        // 🆕 마지막 첨삭 날짜 복원
        for field in lastEditDateFields {
            if let editDate = record[field] as? Date {
                print("📊 CloudKit에서 마지막 날짜 발견:")
                print("  - 필드명: \(field)")
                print("  - 값: \(editDate)")
                
                self.lastEditDate = editDate
                UserDefaults.standard.set(editDate, forKey: lastEditDateKey)
                print("📅 마지막 첨삭 날짜 복원: \(editDate) (필드: \(field))")
                break
            }
        }
        
        // 사용자 이름 복원
        for field in userNameFields {
            if let cloudUserName = record[field] as? String, !cloudUserName.isEmpty {
                self.userName = cloudUserName
                UserDefaults.standard.set(cloudUserName, forKey: userNameKey)
                print("📝 사용자 이름 복원: \(cloudUserName) (필드: \(field))")
                break
            }
        }
        
        // 첨삭 언어 설정 복원
        for field in correctionLanguageFields {
            if let correctionCode = record[field] as? String,
               let correctionLanguage = LanguageManager.availableLanguages.first(where: { $0.languageCode == correctionCode }) {
                LanguageManager.shared.correctionLanguage = correctionLanguage
                UserDefaults.standard.set(correctionCode, forKey: "correction_language_code")
                print("🌍 첨삭 언어 복원: \(correctionCode) (필드: \(field))")
                break
            }
        }
        
        // 모국어 설정 복원
        for field in nativeLanguageFields {
            if let nativeCode = record[field] as? String,
               let nativeLanguage = LanguageManager.availableLanguages.first(where: { $0.languageCode == nativeCode }) {
                LanguageManager.shared.nativeLanguage = nativeLanguage
                UserDefaults.standard.set(nativeCode, forKey: "native_language_code")
                print("🌍 모국어 복원: \(nativeCode) (필드: \(field))")
                break
            }
        }
        
        // 🆕 프리미엄 상태 복원
        for field in premiumFields {
            if let isPremium = record[field] as? Bool {
                self.isPremiumUser = isPremium
                UserDefaults.standard.set(isPremium, forKey: isPremiumUserKey)
                print("💎 프리미엄 상태 복원: \(isPremium) (필드: \(field))")
                break
            }
        }
        
        // 🆕 일일 첨삭 횟수 복원
        for field in dailyEditCountFields {
            if let editCount = record[field] as? Int {
                self.dailyEditCount = editCount
                UserDefaults.standard.set(editCount, forKey: dailyEditCountKey)
                print("📝 일일 첨삭 횟수 복원: \(editCount) (필드: \(field))")
                break
            }
        }
        
        // 🆕 마지막 첨삭 날짜 복원
        for field in lastEditDateFields {
            if let editDate = record[field] as? Date {
                self.lastEditDate = editDate
                UserDefaults.standard.set(editDate, forKey: lastEditDateKey)
                print("📅 마지막 첨삭 날짜 복원: \(editDate) (필드: \(field))")
                break
            }
        }
        
        // 날짜 변경 시 카운트 리셋 체크
        checkAndResetDailyEditCount()
        
        // 온보딩 건너뛰기
        self.needsNameSetup = false
        self.needsLanguageSetup = false
        self.isSettingsLoaded = true
        
        print("✅ CloudKit에서 직접 설정 로드 완료")
    }
    
    // saveSettingsDirectlyToCloudKit 메서드에 추가
    func saveSettingsDirectlyToCloudKit(
        appleUserID: String,
        userName: String,
        correctionLanguageCode: String,
        nativeLanguageCode: String
    ) async {
        let container = CKContainer(identifier: "iCloud.Kodiary")
        let database = container.privateCloudDatabase
        
        print("💾 CloudKit에 직접 저장 시작: \(appleUserID)")
        
        do {
            // 기존 레코드 확인 (기존 로직과 동일)
            let possibleRecordTypes = ["CD_UserSettings", "UserSettings", "CDUserSettings"]
            var existingRecord: CKRecord? = nil
            var recordTypeToUse = "CD_UserSettings"
            
            for recordType in possibleRecordTypes {
                let predicate1 = NSPredicate(format: "CD_appleUserID == %@", appleUserID)
                let query1 = CKQuery(recordType: recordType, predicate: predicate1)
                
                do {
                    let (matchResults, _) = try await database.records(matching: query1)
                    
                    for (_, result) in matchResults {
                        switch result {
                        case .success(let record):
                            existingRecord = record
                            recordTypeToUse = recordType
                            print("✅ 기존 레코드 발견: \(recordType)")
                            break
                        case .failure:
                            break
                        }
                    }
                    
                    if existingRecord != nil {
                        break
                    }
                    
                    // appleUserID 필드명도 다르게 시도
                    let predicate2 = NSPredicate(format: "appleUserID == %@", appleUserID)
                    let query2 = CKQuery(recordType: recordType, predicate: predicate2)
                    
                    let (matchResults2, _) = try await database.records(matching: query2)
                    
                    for (_, result) in matchResults2 {
                        switch result {
                        case .success(let record):
                            existingRecord = record
                            recordTypeToUse = recordType
                            print("✅ 기존 레코드 발견 (두 번째 시도): \(recordType)")
                            break
                        case .failure:
                            break
                        }
                    }
                    
                    if existingRecord != nil {
                        break
                    }
                    
                } catch {
                    print("❌ 기존 레코드 검색 실패 (\(recordType)): \(error)")
                }
            }
            
            let record: CKRecord
            if let existing = existingRecord {
                // 기존 레코드 업데이트
                record = existing
                print("🔄 기존 CloudKit 레코드 업데이트: \(recordTypeToUse)")
            } else {
                // 새 레코드 생성
                record = CKRecord(recordType: recordTypeToUse)
                record["CD_appleUserID"] = appleUserID
                record["appleUserID"] = appleUserID
                record["CD_createdAt"] = Date()
                record["createdAt"] = Date()
                print("🆕 새 CloudKit 레코드 생성: \(recordTypeToUse)")
            }
            
            // 설정 값 업데이트 (기존 + 신규)
            record["CD_userName"] = userName
            record["userName"] = userName
            record["CD_correctionLanguageCode"] = correctionLanguageCode
            record["correctionLanguageCode"] = correctionLanguageCode
            record["CD_nativeLanguageCode"] = nativeLanguageCode
            record["nativeLanguageCode"] = nativeLanguageCode
            record["CD_modifiedAt"] = Date()
            record["modifiedAt"] = Date()
            
            // 🆕 멤버십 관련 데이터 저장
            record["CD_isPremiumUser"] = isPremiumUser
            record["isPremiumUser"] = isPremiumUser
            record["CD_dailyEditCount"] = dailyEditCount
            record["dailyEditCount"] = dailyEditCount
            record["CD_lastEditDate"] = lastEditDate
            record["lastEditDate"] = lastEditDate
            
            // CloudKit에 저장
            let _ = try await database.save(record)
            print("💾 CloudKit에 직접 저장 완료!")
            print("📄 저장된 데이터:")
            print("  - 사용자명: \(userName)")
            print("  - 첨삭언어: \(correctionLanguageCode)")
            print("  - 모국어: \(nativeLanguageCode)")
            print("  - 프리미엄: \(isPremiumUser)")
            print("  - 일일첨삭횟수: \(dailyEditCount)")
            
        } catch {
            print("❌ CloudKit 직접 저장 실패: \(error)")
        }
    }
    
    // 🆕 로그아웃 시 멤버십 데이터도 초기화
    func signOut() {
        // 🆕 로그아웃 전에 현재 상태 로그
        print("🚪 로그아웃 시작 - 현재 첨삭횟수: \(dailyEditCount)")
        
        UserDefaults.standard.removeObject(forKey: isLoggedInKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: isPremiumUserKey)
        UserDefaults.standard.removeObject(forKey: dailyEditCountKey)
        UserDefaults.standard.removeObject(forKey: lastEditDateKey)
        
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.userName = ""
            self.userEmail = ""
            self.needsNameSetup = false
            self.needsLanguageSetup = false
            self.isSettingsLoaded = false
            
            // 🆕 로그아웃 시에는 CloudKit에 0으로 저장하지 않음
            // (다음 로그인 시 CloudKit에서 복원될 예정)
            self.isPremiumUser = false
            self.dailyEditCount = 0
            self.lastEditDate = nil
            
            print("🚪 로그아웃 완료 - 로컬 데이터만 초기화")
        }
    }
    
    
    // MARK: - Apple 로그인 성공 처리
    func handleAppleSignInSuccess(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                let email = appleIDCredential.email ?? ""
                let fullName = appleIDCredential.fullName
                
                // 사용자 정보 저장
                var displayName = extractDisplayName(from: fullName, email: email)
                if displayName.isEmpty { displayName = "사용자" }
                
                saveUserData(userID: userID, name: displayName, email: email)
                
                // UI 업데이트
                Task { @MainActor in
                    self.userName = displayName
                    self.userEmail = email
                    self.isLoading = false
                    self.isLoggedIn = true
                    
                    // CloudKit에서 직접 사용자 설정 확인
                    await self.checkUserSettingsDirectlyFromCloudKit(userID: userID)
                    
                    print("✅ Apple 로그인 성공 - 사용자: \(displayName)")
                }
            }
            
        case .failure(let error):
            print("❌ Apple 로그인 실패: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - CloudKit에서 직접 사용자 설정 확인
    private func checkUserSettingsDirectlyFromCloudKit(userID: String) async {
        print("🔍 CloudKit에서 직접 사용자 설정 확인: \(userID)")
        
        let container = CKContainer(identifier: "iCloud.Kodiary")
        let database = container.privateCloudDatabase
        
        // 여러 가능한 레코드 타입명으로 시도
        let possibleRecordTypes = ["CD_UserSettings", "UserSettings", "CDUserSettings"]
        
        var foundRecord: CKRecord? = nil
        
        for recordType in possibleRecordTypes {
            print("🔍 레코드 타입 시도: \(recordType)")
            
            let predicate = NSPredicate(format: "CD_appleUserID == %@", userID)
            let query = CKQuery(recordType: recordType, predicate: predicate)
            
            do {
                let (matchResults, _) = try await database.records(matching: query)
                
                for (_, result) in matchResults {
                    switch result {
                    case .success(let record):
                        print("✅ 사용자 설정 발견! 레코드 타입: \(recordType)")
                        print("📄 레코드 내용: \(record.allKeys())")
                        foundRecord = record
                        break
                    case .failure(let error):
                        print("❌ 레코드 조회 실패: \(error)")
                    }
                }
                
                if foundRecord != nil {
                    break // 찾으면 루프 종료
                }
                
            } catch {
                print("❌ CloudKit 쿼리 실패 (\(recordType)): \(error)")
                
                // appleUserID 필드명도 다르게 시도
                if recordType == "CD_UserSettings" {
                    let predicate2 = NSPredicate(format: "appleUserID == %@", userID)
                    let query2 = CKQuery(recordType: recordType, predicate: predicate2)
                    
                    do {
                        let (matchResults2, _) = try await database.records(matching: query2)
                        
                        for (_, result) in matchResults2 {
                            switch result {
                            case .success(let record):
                                print("✅ 사용자 설정 발견! (두 번째 시도) 레코드 타입: \(recordType)")
                                print("📄 레코드 내용: \(record.allKeys())")
                                foundRecord = record
                                break
                            case .failure(let error):
                                print("❌ 레코드 조회 실패 (두 번째 시도): \(error)")
                            }
                        }
                        
                        if foundRecord != nil {
                            break
                        }
                        
                    } catch {
                        print("❌ CloudKit 두 번째 쿼리 실패: \(error)")
                    }
                }
            }
        }
        
        await MainActor.run {
            if let record = foundRecord {
                // 기존 사용자 - CloudKit에서 직접 설정 로드
                self.loadSettingsFromCloudKitRecord(record)
            } else {
                // 신규 사용자
                print("🆕 신규 사용자 - CloudKit에 설정 없음 (모든 레코드 타입 시도 완료)")
                self.needsNameSetup = true
                self.needsLanguageSetup = false
            }
        }
    }
    
    // MARK: - 온보딩 완료 시 CloudKit에 직접 저장
    func completeOnboarding() {
        guard let currentUserID = UserDefaults.standard.string(forKey: userIdKey) else {
            print("❌ 사용자 ID가 없음")
            return
        }
        
        print("🎉 온보딩 완료 - CloudKit에 직접 저장 시작")
        
        Task {
            await self.saveSettingsDirectlyToCloudKit(
                appleUserID: currentUserID,
                userName: self.userName,
                correctionLanguageCode: LanguageManager.shared.correctionLanguageCode,
                nativeLanguageCode: LanguageManager.shared.nativeLanguageCode
            )
            
            await MainActor.run {
                self.needsNameSetup = false
                self.needsLanguageSetup = false
                print("✅ 온보딩 완료 - CloudKit에 직접 저장됨")
            }
        }
    }
    
    // MARK: - 사용자 이름 업데이트
    func updateUserName(_ newName: String) {
        DispatchQueue.main.async {
            self.userName = newName
            UserDefaults.standard.set(newName, forKey: self.userNameKey)
            print("📝 사용자 이름 업데이트됨: \(newName)")
        }
        
        // CloudKit에도 업데이트 (온보딩 중이 아닌 경우)
        if !needsNameSetup && !needsLanguageSetup {
            guard let currentUserID = UserDefaults.standard.string(forKey: userIdKey) else { return }
            
            Task {
                await self.saveSettingsDirectlyToCloudKit(
                    appleUserID: currentUserID,
                    userName: newName,
                    correctionLanguageCode: LanguageManager.shared.correctionLanguageCode,
                    nativeLanguageCode: LanguageManager.shared.nativeLanguageCode
                )
            }
        }
    }
    
    // MARK: - 기존 메서드들
    private func saveUserData(userID: String, name: String, email: String) {
        UserDefaults.standard.set(true, forKey: isLoggedInKey)
        UserDefaults.standard.set(name, forKey: userNameKey)
        UserDefaults.standard.set(email, forKey: userEmailKey)
        UserDefaults.standard.set(userID, forKey: userIdKey)
    }
    
    func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            self.isLoading = loading
        }
    }
    
    func proceedToLanguageSetup() {
        DispatchQueue.main.async {
            self.needsNameSetup = false
            self.needsLanguageSetup = true
        }
    }
    
    // MARK: - 헬퍼 메서드
    private func extractDisplayName(from fullName: PersonNameComponents?, email: String) -> String {
        if let givenName = fullName?.givenName,
           let familyName = fullName?.familyName {
            return "\(familyName)\(givenName)"
        } else if let givenName = fullName?.givenName {
            return givenName
        } else if !email.isEmpty && !email.contains("privaterelay.appleid.com") {
            return String(email.split(separator: "@")[0])
        }
        return ""
    }
}
