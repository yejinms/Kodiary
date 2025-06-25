import SwiftUI

struct AppTourView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    // 앱 투어 기능들
    private var tourFeatures: [TourFeature] {
        [
            TourFeature(
                icon: "📝",
                title: languageManager.currentLanguage.appTourFeature1Title,
                description: languageManager.currentLanguage.appTourFeature1Description,
                backgroundColor: Color.primaryBlue
            ),
            TourFeature(
                icon: "🎯",
                title: languageManager.currentLanguage.appTourFeature2Title,
                description: languageManager.currentLanguage.appTourFeature2Description,
                backgroundColor: Color.primaryYellow
            ),
            TourFeature(
                icon: "📊",
                title: languageManager.currentLanguage.appTourFeature3Title,
                description: languageManager.currentLanguage.appTourFeature3Description,
                backgroundColor: Color.primaryBlue.opacity(0.8)
            ),
            TourFeature(
                icon: "🌍",
                title: languageManager.currentLanguage.appTourFeature4Title,
                description: languageManager.currentLanguage.appTourFeature4Description,
                backgroundColor: Color.primaryYellow.opacity(0.8)
            )
        ]
    }
    
    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 헤더
                HStack {
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primaryDark)
                            .frame(width: 44, height: 44)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // 메인 콘텐츠
                VStack(spacing: 30) {
                    // 타이틀
                    VStack(spacing: 16) {
                        Text(languageManager.currentLanguage.appTourTitle)
                            .font(.titleLarge)
                            .foregroundColor(.primaryDark)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    
                    // 페이지 인디케이터
                    HStack(spacing: 8) {
                        ForEach(0..<tourFeatures.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.primaryDark : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    .padding(.top, 10)
                    
                    // 캐러셀 뷰
                    TabView(selection: $currentPage) {
                        ForEach(Array(tourFeatures.enumerated()), id: \.offset) { index, feature in
                            TourFeatureCard(feature: feature)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 400)
                    .animation(.easeInOut, value: currentPage)
                    
                    Spacer()
                    
                    // 하단 버튼들
                    VStack(spacing: 16) {
                        // 시작하기 버튼
                        Button(action: {
                            isPresented = false
                        }) {
                            Text(languageManager.currentLanguage.appTourGetStarted)
                                .font(.buttonFont)
                                .foregroundColor(.primaryDark)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.primaryYellow)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 40)
                        
                        // 건너뛰기 버튼
                        Button(action: {
                            isPresented = false
                        }) {
                            Text(languageManager.currentLanguage.appTourSkip)
                                .font(.buttonFontSmall)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

// 투어 기능 데이터 모델
struct TourFeature {
    let icon: String
    let title: String
    let description: String
    let backgroundColor: Color
}

// 투어 기능 카드 컴포넌트
struct TourFeatureCard: View {
    let feature: TourFeature
    
    var body: some View {
        VStack(spacing: 24) {
            // 아이콘 배경
            ZStack {
                Circle()
                    .fill(feature.backgroundColor)
                    .frame(width: 120, height: 120)
                    .shadow(color: .primaryDark.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Text(feature.icon)
                    .font(.system(size: 50))
            }
            
            // 텍스트 영역
            VStack(spacing: 16) {
                Text(feature.title)
                    .font(.bodyFont)
                    .foregroundColor(.primaryDark)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(.bodyFont)
                    .foregroundColor(.primaryDark.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct AppTourView_Previews: PreviewProvider {
    @State static var isPresented = true
    
    static var previews: some View {
        AppTourView(isPresented: $isPresented)
            .environmentObject(LanguageManager.shared)
    }
}
