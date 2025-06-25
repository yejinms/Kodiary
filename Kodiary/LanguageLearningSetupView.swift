import SwiftUI

struct LanguageLearningSetupView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedLanguage: LanguageTexts?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 헤더
            VStack(spacing: 20) {
                // 학습 아이콘
                ZStack {
                    Circle()
                        .fill(Color.primaryBlue)
                        .frame(width: 100, height: 100)
                        .shadow(color: .primaryDark.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Text("📚")
                        .font(.system(size: 50))
                }
                
                VStack(spacing: 12) {
                    Text(languageManager.currentLanguage.languageLearningWelcomeTitle(userManager.userName))
                        .font(.titleLarge)
                        .foregroundColor(.primaryDark)
                        .multilineTextAlignment(.center)
                    
                    Text(languageManager.currentLanguage.languageLearningWelcomeSubtitle)
                        .font(.bodyFont)
                        .foregroundColor(.primaryDark.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(5)
                }
            }
            
            Spacer()
            
            // 언어 선택 섹션
            VStack(spacing: 20) {
                Text(languageManager.currentLanguage.languageLearningPrompt)
                    .font(.bodyFontTitle)
                    .foregroundColor(.primaryDark)
                
                // 언어 목록 (스크롤 가능)
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(LanguageManager.availableLanguages, id: \.languageCode) { language in
                            LanguageSelectionCard(
                                language: language,
                                isSelected: selectedLanguage?.languageCode == language.languageCode,
                                onTap: {
                                    selectedLanguage = language
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 300)
            }
            
            Spacer()
            
            // 계속하기 버튼
            Button(action: {
                completeSetup()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryDark))
                            .scaleEffect(0.8)
                    } else {
                        Text(languageManager.currentLanguage.languageLearningContinueButton)
                            .font(.buttonFont)
                            .foregroundColor(.primaryDark)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canProceed ? Color.primaryBlue : Color.primaryDark.opacity(0.2))
                .cornerRadius(8)
            }
            .disabled(!canProceed || isLoading)
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .background(Color.background)
        .onAppear {
            // 기본값으로 한국어 선택
            selectedLanguage = LanguageManager.korean
        }
    }
    
    // MARK: - Computed Properties
    private var canProceed: Bool {
        selectedLanguage != nil
    }
    
    // MARK: - Actions
    private func completeSetup() {
        guard let selectedLanguage = selectedLanguage else { return }
        
        isLoading = true
        
        // 선택한 언어를 첨삭 언어로 설정
        languageManager.setCorrectionLanguage(selectedLanguage)
        
        // 온보딩 완료
        userManager.completeOnboarding()
        
        // 로딩 애니메이션을 위한 딜레이
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }
}

// 언어 선택 카드 컴포넌트
struct LanguageSelectionCard: View {
    let language: LanguageTexts
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(language.flag)
                    .font(.system(size: 40))
                
                Text(language.languageName)
                    .font(.buttonFontSmall)
                    .foregroundColor(.primaryDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.primaryYellow.opacity(0.3) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primaryDark : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LanguageLearningSetupView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageLearningSetupView()
            .environmentObject(UserManager.shared)
            .environmentObject(LanguageManager.shared)
    }
}
