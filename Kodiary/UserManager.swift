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
    
    // UserDefaults 키들
    private let isLoggedInKey = "is_logged_in"
    private let userNameKey = "user_name"
    private let userEmailKey = "user_email"
    private let userIdKey = "user_id"
    
    private init() {
        loadUserData()
    }
    
    // MARK: - 저장된 사용자 데이터 로드
    private func loadUserData() {
        isLoggedIn = UserDefaults.standard.bool(forKey: isLoggedInKey)
        userName = UserDefaults.standard.string(forKey: userNameKey) ?? ""
        userEmail = UserDefaults.standard.string(forKey: userEmailKey) ?? ""
        
        // 이미 로그인된 상태면 설정도 로드된 것으로 처리
        if isLoggedIn {
            isSettingsLoaded = true
            print("🔐 기존 로그인 상태 - 설정 로드 완료로 처리")
        }
        
        print("🔐 사용자 데이터 로드됨 - 로그인: \(isLoggedIn), 이름: \(userName)")
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
    
    // MARK: - CloudKit 레코드에서 설정 로드
    private func loadSettingsFromCloudKitRecord(_ record: CKRecord) {
        print("👤 기존 사용자 설정 CloudKit에서 직접 로드")
        print("📄 레코드의 모든 키: \(record.allKeys())")
        
        // 여러 가능한 필드명으로 시도
        let userNameFields = ["CD_userName", "userName", "CDuserName"]
        let correctionLanguageFields = ["CD_correctionLanguageCode", "correctionLanguageCode", "CDcorrectionLanguageCode"]
        let nativeLanguageFields = ["CD_nativeLanguageCode", "nativeLanguageCode", "CDnativeLanguageCode"]
        
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
        
        // 온보딩 건너뛰기
        self.needsNameSetup = false
        self.needsLanguageSetup = false
        self.isSettingsLoaded = true
        
        print("✅ CloudKit에서 직접 설정 로드 완료")
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
    
    // MARK: - CloudKit에 직접 저장 (public으로 변경)
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
            // 기존 레코드 확인 (여러 레코드 타입과 필드명으로 시도)
            let possibleRecordTypes = ["CD_UserSettings", "UserSettings", "CDUserSettings"]
            var existingRecord: CKRecord? = nil
            var recordTypeToUse = "CD_UserSettings" // 기본값
            
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
                record["appleUserID"] = appleUserID // 두 가지 필드명 모두 설정
                record["CD_createdAt"] = Date()
                record["createdAt"] = Date()
                print("🆕 새 CloudKit 레코드 생성: \(recordTypeToUse)")
            }
            
            // 설정 값 업데이트 (두 가지 필드명 모두 설정)
            record["CD_userName"] = userName
            record["userName"] = userName
            record["CD_correctionLanguageCode"] = correctionLanguageCode
            record["correctionLanguageCode"] = correctionLanguageCode
            record["CD_nativeLanguageCode"] = nativeLanguageCode
            record["nativeLanguageCode"] = nativeLanguageCode
            record["CD_modifiedAt"] = Date()
            record["modifiedAt"] = Date()
            
            // CloudKit에 저장
            let _ = try await database.save(record)
            print("💾 CloudKit에 직접 저장 완료!")
            print("📄 저장된 데이터:")
            print("  - 사용자명: \(userName)")
            print("  - 첨삭언어: \(correctionLanguageCode)")
            print("  - 모국어: \(nativeLanguageCode)")
            
        } catch {
            print("❌ CloudKit 직접 저장 실패: \(error)")
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
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: isLoggedInKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.userName = ""
            self.userEmail = ""
            self.needsNameSetup = false
            self.needsLanguageSetup = false
            self.isSettingsLoaded = false
            print("🚪 로그아웃 완료")
        }
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
