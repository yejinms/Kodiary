import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var languageManager: LanguageManager  // 추가
    
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
                
                Text(languageManager.currentLanguage.profileUserName)
                    .font(.titleLarge)
                    .foregroundColor(.primaryDark)
            }
            .padding(.top, Spacing.xl)
            
            // 설정 메뉴들
            VStack(spacing: Spacing.md) {
                SettingsRow(
                    icon: "person",
                    title: languageManager.currentLanguage.profileInfoTitle,
                    action: { /* 프로필 정보 수정 */ }
                )
                
                SettingsRow(
                    icon: "bell",
                    title: languageManager.currentLanguage.notificationSettingsTitle,
                    action: { /* 알림 설정 */ }
                )
                
                SettingsRow(
                    icon: "lock",
                    title: languageManager.currentLanguage.privacySettingsTitle,
                    action: { /* 개인정보 보호 설정 */ }
                )
                
                SettingsRow(
                    icon: "questionmark.circle",
                    title: languageManager.currentLanguage.helpTitle,
                    action: { /* 도움말 */ }
                )
                
                SettingsRow(
                    icon: "info.circle",
                    title: languageManager.currentLanguage.appInfoTitle,
                    action: { /* 앱 정보 */ }
                )
            }
            .padding(.horizontal, Spacing.lg)
            
            Spacer()
        }
        .background(Color.background)
        .navigationTitle(languageManager.currentLanguage.profileSettingsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 설정 행 컴포넌트 (변경 없음)
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
        }
    }
}
