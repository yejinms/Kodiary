import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 커스텀 탭 헤더
                VStack(spacing: 12) {
                    Text(languageManager.currentLanguage.languageSettingsTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    // 탭 선택기
                    HStack(spacing: 0) {
                        TabButton(
                            title: languageManager.currentLanguage.correctionLanguageTab,
                            isSelected: selectedTab == 0
                        ) {
                            selectedTab = 0
                        }
                        
                        TabButton(
                            title: languageManager.currentLanguage.nativeLanguageTab,
                            isSelected: selectedTab == 1
                        ) {
                            selectedTab = 1
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // 탭 내용
                TabView(selection: $selectedTab) {
                    
                    // 첨삭 언어 설정 탭
                    CorrectionLanguageTab()
                        .tag(0)
                    
                    // 모국어 설정 탭
                    NativeLanguageTab()
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.currentLanguage.confirmButton) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 탭 버튼 컴포넌트
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// 모국어 설정 탭
struct NativeLanguageTab: View {
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 설명
                VStack(spacing: 8) {
                    Text(languageManager.currentLanguage.nativeLanguageDescription)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)
                
                // 언어 선택 카드들
                VStack(spacing: 12) {
                    ForEach(Array(LanguageManager.availableLanguages.enumerated()), id: \.offset) { index, language in
                        LanguageCard(
                            language: language,
                            isSelected: language.languageCode == languageManager.nativeLanguage.languageCode,
                            showSampleText: true
                        ) {
                            languageManager.setNativeLanguage(language)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 100)
            }
        }
    }
}

// 첨삭 언어 설정 탭
struct CorrectionLanguageTab: View {
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 설명
                VStack(spacing: 8) {
                    Text(languageManager.currentLanguage.correctionLanguageDescription)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)
                
                // 언어 선택 카드들
                VStack(spacing: 12) {
                    ForEach(Array(LanguageManager.availableLanguages.enumerated()), id: \.offset) { index, language in
                        LanguageCard(
                            language: language,
                            isSelected: language.languageCode == languageManager.correctionLanguage.languageCode,
                            showSampleText: false
                        ) {
                            languageManager.setCorrectionLanguage(language)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 100)
            }
        }
    }
}

// 언어 카드 컴포넌트 (개선됨)
struct LanguageCard: View {
    let language: LanguageTexts
    let isSelected: Bool
    let showSampleText: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 국기
                Text(language.flag)
                    .font(.system(size: 35))
                
                VStack(alignment: .leading, spacing: 4) {
                    // 언어 이름
                    Text(language.languageName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    // 예시 텍스트 (모국어 설정에서만 표시)
                    if showSampleText {
                        Text(sampleText)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    } else {
                        Text(correctionSampleText)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // 선택 표시
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var sampleText: String {
        switch language.languageCode {
        case "ko":
            return "오늘의 일기 쓰기"
        case "en":
            return "Write Today's Diary"
        case "ja":
            return "今日の日記を書く"
        default:
            return "Sample text"
        }
    }
    
    var correctionSampleText: String {
        switch language.languageCode {
        case "ko":
            return "한국어로 일기 작성"
        case "en":
            return "Write diary in English"
        case "ja":
            return "日本語で日記を書く"
        default:
            return "Diary language"
        }
    }
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView()
            .environmentObject(LanguageManager.shared)
    }
}
