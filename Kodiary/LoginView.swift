//
//  LoginView.swift
//  Kodiary
//
//  Created by Niko on 6/25/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showingLanguageSelection = false
    @State private var showingAppTour = false // 앱 둘러보기 상태 추가
    
    var body: some View {
        ZStack {
            // 배경색
            Color.background
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 앱 로고 및 제목
                VStack(spacing: 20) {
                    // 앱 아이콘 (원형)
                        Image("KoDiary_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 5)
                   
                    // 앱 이름
                    Text("Kodiary")
                        .font(.custom("GravitasOne", size: 36))
                        .foregroundColor(.primaryDark)
                    
                    // 앱 설명
                    Text(languageManager.currentLanguage.appDescription)
                        .font(.bodyFont)
                        .foregroundColor(.primaryDark.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(5)
                }
                
                Spacer()
                
                // 로그인 섹션
                VStack(spacing: 24) {
                    // Apple 로그인 버튼
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            userManager.handleAppleSignInSuccess(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(8)
                    .padding(.horizontal, 40)
                    
                    // 앱 둘러보기 버튼 (새로 추가)
                    Button(action: {
                        showingAppTour = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "eye")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(languageManager.currentLanguage.appTourButton)
                                .font(.buttonFont)
                        }
                        .foregroundColor(.primaryDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primaryBlue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primaryDark.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 40)
                    
                    // 개인정보 처리방침 등 안내
                    Text(languageManager.currentLanguage.privacyNotice)
                        .font(.buttonFontSmall)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(3)
                }
                
                Spacer()
            }
            
            // 로딩 오버레이
            if userManager.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryDark))
                        .scaleEffect(1.2)
                    
                    Text(languageManager.currentLanguage.signingInMessage)
                        .font(.bodyFont)
                        .foregroundColor(.primaryDark)
                }
                .padding(32)
                .background(Color.background)
                .cornerRadius(16)
                .shadow(radius: 10)
            }
        }
        .sheet(isPresented: $showingLanguageSelection) {
            LanguageSelectionView()
                .environmentObject(languageManager)
        }
        .fullScreenCover(isPresented: $showingAppTour) { // 앱 둘러보기 모달 추가
            AppTourView(isPresented: $showingAppTour)
                .environmentObject(languageManager)
        }
        .onAppear {
            // 로딩 상태 초기화
            userManager.setLoading(false)
        }
        .onChange(of: userManager.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                // 로그인 성공 시 로딩 해제
                userManager.setLoading(false)
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(UserManager.shared)
            .environmentObject(LanguageManager.shared)
    }
}
