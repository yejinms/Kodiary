//
//  UserSettingManager.swift
//  Kodiary
//
//  Created by Niko on 6/25/25.
//

import Foundation
import CoreData
import CloudKit

// UserSettings 관리 클래스
class UserSettingsManager: ObservableObject {
    static let shared = UserSettingsManager()
    
    @Published var isSettingsSynced = false
    
    private var dataManager: DataManager {
        return DataManager.shared
    }
    
    private init() {}
    
    // MARK: - 사용자 설정 저장 (CloudKit + UserDefaults)
    func saveUserSettings(
        appleUserID: String,
        userName: String,
        correctionLanguageCode: String,
        nativeLanguageCode: String
    ) {
        print("💾 사용자 설정 저장 시작...")
        
        // 1. CloudKit에 저장
        saveToCloudKit(
            appleUserID: appleUserID,
            userName: userName,
            correctionLanguageCode: correctionLanguageCode,
            nativeLanguageCode: nativeLanguageCode
        )
        
        // 2. UserDefaults에도 백업 저장 (즉시 사용을 위해)
        saveToUserDefaults(
            userName: userName,
            correctionLanguageCode: correctionLanguageCode,
            nativeLanguageCode: nativeLanguageCode
        )
        
        print("✅ 사용자 설정 저장 완료")
    }
    
    // MARK: - CloudKit에 사용자 설정 저장
    private func saveToCloudKit(
        appleUserID: String,
        userName: String,
        correctionLanguageCode: String,
        nativeLanguageCode: String
    ) {
        let context = dataManager.context
        
        // 기존 설정이 있는지 확인
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.predicate = NSPredicate(format: "appleUserID == %@", appleUserID)
        
        do {
            let existingSettings = try context.fetch(request)
            
            let userSettings: UserSettings
            if let existing = existingSettings.first {
                // 기존 설정 업데이트
                userSettings = existing
                print("🔄 기존 사용자 설정 업데이트")
            } else {
                // 새 설정 생성
                userSettings = UserSettings(context: context)
                userSettings.id = UUID()
                userSettings.appleUserID = appleUserID
                userSettings.createdAt = Date()
                print("🆕 새 사용자 설정 생성")
            }
            
            // 설정 값 업데이트
            userSettings.userName = userName
            userSettings.correctionLanguageCode = correctionLanguageCode
            userSettings.nativeLanguageCode = nativeLanguageCode
            userSettings.modifiedAt = Date()
            
            // Core Data 저장 (CloudKit 자동 동기화)
            try context.save()
            print("💾 사용자 설정 CloudKit 저장 완료")
            
        } catch {
            print("❌ 사용자 설정 CloudKit 저장 실패: \(error)")
        }
    }
    
    // MARK: - UserDefaults에 백업 저장
    private func saveToUserDefaults(
        userName: String,
        correctionLanguageCode: String,
        nativeLanguageCode: String
    ) {
        UserDefaults.standard.set(userName, forKey: "user_name")
        UserDefaults.standard.set(correctionLanguageCode, forKey: "correction_language_code")
        UserDefaults.standard.set(nativeLanguageCode, forKey: "native_language_code")
        print("💾 사용자 설정 UserDefaults 백업 완료")
    }
    
    // MARK: - 사용자 설정 로드 (CloudKit -> UserDefaults)
    func loadUserSettings(for appleUserID: String) async {
        print("📱 사용자 설정 로드 시작: \(appleUserID)")
        
        let context = dataManager.context
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.predicate = NSPredicate(format: "appleUserID == %@", appleUserID)
        
        do {
            let userSettings = try context.fetch(request)
            
            if let settings = userSettings.first {
                // CloudKit에서 설정을 찾았음
                await MainActor.run {
                    self.applySettingsToManagers(settings)
                    self.isSettingsSynced = true
                }
                print("✅ CloudKit에서 사용자 설정 로드 완료")
            } else {
                // CloudKit에 설정이 없음 (신규 사용자)
                await MainActor.run {
                    self.isSettingsSynced = false
                }
                print("⚠️ CloudKit에 사용자 설정 없음 - 신규 사용자")
            }
            
        } catch {
            print("❌ 사용자 설정 로드 실패: \(error)")
            await MainActor.run {
                self.isSettingsSynced = false
            }
        }
    }
    
    // MARK: - 설정을 각 Manager에 적용
    private func applySettingsToManagers(_ settings: UserSettings) {
        // UserManager에 이름 설정
        UserManager.shared.updateUserName(settings.userName ?? "사용자")
        
        // LanguageManager에 언어 설정
        if let correctionCode = settings.correctionLanguageCode,
           let correctionLanguage = LanguageManager.availableLanguages.first(where: { $0.languageCode == correctionCode }) {
            LanguageManager.shared.setCorrectionLanguage(correctionLanguage)
        }
        
        if let nativeCode = settings.nativeLanguageCode,
           let nativeLanguage = LanguageManager.availableLanguages.first(where: { $0.languageCode == nativeCode }) {
            LanguageManager.shared.setNativeLanguage(nativeLanguage)
        }
        
        print("🔄 설정이 각 Manager에 적용됨")
    }
    
    // MARK: - 설정 존재 여부 확인
    func hasCloudKitSettings(for appleUserID: String) async -> Bool {
        let context = dataManager.context
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.predicate = NSPredicate(format: "appleUserID == %@", appleUserID)
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("❌ 설정 존재 여부 확인 실패: \(error)")
            return false
        }
    }
}
