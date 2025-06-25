import Foundation
import AuthenticationServices
import SwiftUI

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var isLoggedIn = false
    @Published var userName = ""
    @Published var userEmail = ""
    @Published var isLoading = false
    @Published var needsNameSetup = false
    @Published var needsLanguageSetup = false
    
    // UserDefaults 키들
    private let isLoggedInKey = "is_logged_in"
    private let userNameKey = "user_name"
    private let userEmailKey = "user_email"
    private let userIdKey = "user_id"
    
    // Apple ID별 설정 저장을 위한 키들
    private func nameSetupCompleteKey(for userID: String) -> String {
        return "name_setup_complete_\(userID)"
    }
    
    private func onboardingCompleteKey(for userID: String) -> String {
        return "onboarding_complete_\(userID)"
    }
    
    private func savedUserNameKey(for userID: String) -> String {
        return "saved_user_name_\(userID)"
    }
    
    private init() {
        loadUserData()
    }
    
    // MARK: - 저장된 사용자 데이터 로드
    private func loadUserData() {
        isLoggedIn = UserDefaults.standard.bool(forKey: isLoggedInKey)
        userName = UserDefaults.standard.string(forKey: userNameKey) ?? ""
        userEmail = UserDefaults.standard.string(forKey: userEmailKey) ?? ""
        
        // 현재 로그인된 사용자의 ID가 있다면 해당 사용자의 설정 확인
        if let currentUserID = UserDefaults.standard.string(forKey: userIdKey), isLoggedIn {
            checkUserSetupStatus(for: currentUserID)
        } else {
            needsNameSetup = false
            needsLanguageSetup = false
        }
        
        print("🔐 사용자 데이터 로드됨 - 로그인: \(isLoggedIn), 이름: \(userName)")
        print("🔧 이름설정필요: \(needsNameSetup), 언어설정필요: \(needsLanguageSetup)")
    }
    
    // MARK: - 특정 사용자의 설정 상태 확인
    private func checkUserSetupStatus(for userID: String) {
        let nameSetupComplete = UserDefaults.standard.bool(forKey: nameSetupCompleteKey(for: userID))
        let onboardingComplete = UserDefaults.standard.bool(forKey: onboardingCompleteKey(for: userID))
        
        needsNameSetup = !nameSetupComplete
        needsLanguageSetup = nameSetupComplete && !onboardingComplete
        
        // 이전에 저장된 이름이 있다면 복원
        if let savedName = UserDefaults.standard.string(forKey: savedUserNameKey(for: userID)), !savedName.isEmpty {
            userName = savedName
            UserDefaults.standard.set(savedName, forKey: userNameKey)
        }
        
        print("👤 사용자 \(userID)의 설정 상태:")
        print("   이름설정완료: \(nameSetupComplete)")
        print("   온보딩완료: \(onboardingComplete)")
        print("   저장된이름: \(userName)")
    }
    
    // MARK: - Apple 로그인 성공 처리
    func handleAppleSignInSuccess(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                let email = appleIDCredential.email ?? ""
                let fullName = appleIDCredential.fullName
                
                // 기존 사용자인지 확인
                let isReturningUser = UserDefaults.standard.bool(forKey: nameSetupCompleteKey(for: userID))
                
                var displayName = ""
                
                if isReturningUser {
                    // 기존 사용자: 저장된 이름 복원
                    if let savedName = UserDefaults.standard.string(forKey: savedUserNameKey(for: userID)), !savedName.isEmpty {
                        displayName = savedName
                        print("🔄 기존 사용자 복원: \(displayName)")
                    } else {
                        // 저장된 이름이 없다면 기본값
                        displayName = "사용자"
                    }
                } else {
                    // 새 사용자: Apple에서 제공하는 이름 처리
                    if let givenName = fullName?.givenName,
                       let familyName = fullName?.familyName {
                        displayName = "\(familyName)\(givenName)"
                        print("📝 Apple에서 전체 이름 받음: \(displayName)")
                    } else if let givenName = fullName?.givenName {
                        displayName = givenName
                        print("📝 Apple에서 이름만 받음: \(displayName)")
                    } else {
                        print("⚠️ Apple에서 이름 정보를 제공하지 않음")
                        
                        if !email.isEmpty && !email.contains("privaterelay.appleid.com") {
                            let emailPrefix = String(email.split(separator: "@")[0])
                            displayName = emailPrefix
                            print("📝 실제 이메일에서 이름 추출: \(displayName)")
                        } else {
                            displayName = "사용자"
                            print("📝 기본 이름 사용: \(displayName)")
                        }
                    }
                }
                
                if displayName.isEmpty {
                    displayName = "사용자"
                }
                
                // 사용자 정보 저장
                saveUserData(userID: userID, name: displayName, email: email)
                
                // 해당 사용자의 설정 상태 확인
                checkUserSetupStatus(for: userID)
                
                // UI 업데이트
                Task { @MainActor in
                    self.userName = displayName
                    self.userEmail = email
                    self.isLoading = false
                    
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    self.isLoggedIn = true
                    
                    if isReturningUser {
                        print("🎉 기존 사용자 복귀 - 설정 건너뛰기 가능")
                    } else {
                        print("👋 새 사용자 - 설정 필요")
                    }
                    
                    print("✅ Apple 로그인 성공 - 사용자: \(displayName)")
                    print("🔧 이름설정필요: \(self.needsNameSetup), 언어설정필요: \(self.needsLanguageSetup)")
                }
            }
            
        case .failure(let error):
            print("❌ Apple 로그인 실패: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - 사용자 데이터 저장
    private func saveUserData(userID: String, name: String, email: String) {
        UserDefaults.standard.set(true, forKey: isLoggedInKey)
        UserDefaults.standard.set(name, forKey: userNameKey)
        UserDefaults.standard.set(email, forKey: userEmailKey)
        UserDefaults.standard.set(userID, forKey: userIdKey)
        
        // Apple ID별로도 이름 저장
        UserDefaults.standard.set(name, forKey: savedUserNameKey(for: userID))
    }
    
    // MARK: - 로그아웃 (설정은 유지)
    func signOut() {
        // 현재 세션 정보만 삭제, Apple ID별 설정은 유지
        UserDefaults.standard.removeObject(forKey: isLoggedInKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        
        // ⚠️ Apple ID별 설정은 삭제하지 않음!
        // nameSetupCompleteKey, onboardingCompleteKey, savedUserNameKey는 그대로 유지
        
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.userName = ""
            self.userEmail = ""
            self.needsNameSetup = false
            self.needsLanguageSetup = false
            print("🚪 로그아웃 완료 (설정은 유지됨)")
        }
    }
    
    // MARK: - 완전 초기화 (개발/테스트용)
    func resetAllData() {
        // 모든 Apple ID의 설정까지 완전 삭제
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        for key in allKeys {
            if key.contains("name_setup_complete_") ||
               key.contains("onboarding_complete_") ||
               key.contains("saved_user_name_") {
                userDefaults.removeObject(forKey: key)
            }
        }
        
        signOut()
        print("🗑️ 모든 데이터 완전 초기화")
    }
    
    // MARK: - 로딩 상태 관리
    func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            self.isLoading = loading
        }
    }
    
    // MARK: - 사용자 이름 업데이트
    func updateUserName(_ newName: String) {
        guard let currentUserID = UserDefaults.standard.string(forKey: userIdKey) else { return }
        
        DispatchQueue.main.async {
            self.userName = newName
            UserDefaults.standard.set(newName, forKey: self.userNameKey)
            // Apple ID별로도 저장
            UserDefaults.standard.set(newName, forKey: self.savedUserNameKey(for: currentUserID))
            print("📝 사용자 이름 업데이트됨: \(newName)")
        }
    }
    
    // MARK: - 이름 설정 완료
    func completeNameSetup() {
        guard let currentUserID = UserDefaults.standard.string(forKey: userIdKey) else { return }
        
        DispatchQueue.main.async {
            self.needsNameSetup = false
            UserDefaults.standard.set(true, forKey: self.nameSetupCompleteKey(for: currentUserID))
            print("✅ 이름 설정 완료 (사용자: \(currentUserID))")
        }
    }
    
    // MARK: - 언어 설정으로 진행
    func proceedToLanguageSetup() {
        guard let currentUserID = UserDefaults.standard.string(forKey: userIdKey) else { return }
        
        DispatchQueue.main.async {
            self.needsNameSetup = false
            self.needsLanguageSetup = true
            UserDefaults.standard.set(true, forKey: self.nameSetupCompleteKey(for: currentUserID))
            print("➡️ 언어 설정으로 진행 (사용자: \(currentUserID))")
        }
    }
    
    // MARK: - 온보딩 완료
    func completeOnboarding() {
        guard let currentUserID = UserDefaults.standard.string(forKey: userIdKey) else { return }
        
        DispatchQueue.main.async {
            self.needsNameSetup = false
            self.needsLanguageSetup = false
            UserDefaults.standard.set(true, forKey: self.onboardingCompleteKey(for: currentUserID))
            print("🎉 온보딩 완료 (사용자: \(currentUserID))")
        }
    }
}
