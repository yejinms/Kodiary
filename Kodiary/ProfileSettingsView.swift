import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var userManager: UserManager
    @State private var showingHelpView = false
    @State private var showingLogoutAlert = false
    @State private var showingNameEditAlert = false
    @State private var editingName = ""
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // 프로필 헤더
            VStack(spacing: Spacing.md) {
                Circle()
                    .fill(Color.primaryDark.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.primaryDark)
                    )
                
                // 동적 사용자 이름 표시 (탭 가능)
                Button(action: {
                    editingName = userManager.userName
                    showingNameEditAlert = true
                }) {
                    HStack(spacing: 10) {
                        Text(userManager.userName.isEmpty ? languageManager.currentLanguage.profileUserName : userManager.userName)
                            .font(.titleLarge)
                            .foregroundColor(.primaryDark)
                        
                        Image(systemName: "pencil")
                            .font(.bodyFont)
                            .foregroundColor(.primaryDark.opacity(0.5))
                    }
                }
            }
            .padding(.top, Spacing.xl)
            
            // 설정 메뉴들
            VStack(spacing: Spacing.md) {
                
//                SettingsRow(
//                    icon: "bell",
//                    title: languageManager.currentLanguage.notificationSettingsTitle,
//                    action: { /* 알림 설정 */ }
//                )
                
                SettingsRow(
                    icon: "lock",
                    title: languageManager.currentLanguage.privacySettingsTitle,
                    action: {
                        if let url = URL(string: "https://kodiaryprivacy.notion.site/21e3ad23e7438017b341cffc3a297337") {
                            openURL(url)
                        }
                    }
                )

                
                SettingsRow(
                    icon: "questionmark.circle",
                    title: languageManager.currentLanguage.helpTitle,
                    action: {
                        showingHelpView = true
                    }
                )
                
                SettingsRow(
                    icon: "info.circle",
                    title: languageManager.currentLanguage.appInfoTitle,
                    action: {
                        if let url = URL(string: "https://kodiaryterms.notion.site/21e3ad23e743808e90c7f516ded66315?pvs=73") {
                            openURL(url)
                        }
                    }
                )
                
                // 로그아웃 버튼 (빨간색으로 구분)
                SettingsRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: languageManager.currentLanguage.signOutButton,
                    action: {
                        showingLogoutAlert = true
                    }
                )
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
            
            Spacer()
        }
        .background(Color.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // 커스텀 백버튼 (좌측)
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.primaryDark.opacity(0.5))
                }
            }
        }
        .sheet(isPresented: $showingHelpView) {
            NavigationView {
                HelpView()
                    .environmentObject(languageManager)
            }
        }
        .alert("이름 변경", isPresented: $showingNameEditAlert) {
            TextField("이름을 입력하세요", text: $editingName)
                .textInputAutocapitalization(.words)
            
            Button("취소", role: .cancel) {
                editingName = ""
            }
            
            Button("저장") {
                if !editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    userManager.updateUserName(editingName.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                editingName = ""
            }
        } message: {
            Text("새로운 이름을 입력해주세요")
        }
        .alert("로그아웃", isPresented: $showingLogoutAlert) {
            Button("취소", role: .cancel) { }
            Button("로그아웃", role: .destructive) {
                print("🚪 로그아웃 버튼 클릭됨")
                userManager.signOut()
            }
        } message: {
            Text("정말 로그아웃 하시겠습니까?")
        }
    }
}

// 설정 행 컴포넌트
struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.primaryDark)
                    .frame(width: 30)
                
                Text(title)
                    .font(.bodyFont)
                    .foregroundColor(.primaryDark)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.primaryDark.opacity(0.5))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.background)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileSettingsView()
                .environmentObject(LanguageManager.shared)
                .environmentObject(UserManager.shared)
        }
    }
}
