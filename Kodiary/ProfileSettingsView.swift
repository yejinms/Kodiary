//
//  ProfileSettingsView.swift
//  Kodiary
//
//  Created by Niko on 6/20/25.
//

import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                
                Text("사용자")
                    .font(.titleLarge)
                    .foregroundColor(.primaryDark)
            }
            .padding(.top, Spacing.xl)
            
            // 설정 메뉴들
            VStack(spacing: Spacing.md) {
                SettingsRow(
                    icon: "person",
                    title: "프로필 정보",
                    action: { /* 프로필 정보 수정 */ }
                )
                
                SettingsRow(
                    icon: "bell",
                    title: "알림 설정",
                    action: { /* 알림 설정 */ }
                )
                
                SettingsRow(
                    icon: "lock",
                    title: "개인정보 보호",
                    action: { /* 개인정보 보호 설정 */ }
                )
                
                SettingsRow(
                    icon: "questionmark.circle",
                    title: "도움말",
                    action: { /* 도움말 */ }
                )
                
                SettingsRow(
                    icon: "info.circle",
                    title: "앱 정보",
                    action: { /* 앱 정보 */ }
                )
            }
            .padding(.horizontal, Spacing.lg)
            
            Spacer()
        }
        .background(Color.background)
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
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
        }
    }
}
