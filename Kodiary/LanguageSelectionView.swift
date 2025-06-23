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
                        .font(.titleLarge)
                        .padding(.vertical, 20)
                    
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
                    .font(.buttonFont)
                    .foregroundColor(.primaryDark)
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
                    .font(.bodyFontTitle)
                    .foregroundColor(isSelected ? .primaryDark : .primaryDark.opacity(0.2))
                
                Rectangle()
                    .fill(isSelected ? Color.primaryDark : Color.clear)
                    .frame(height: 2)
                    .padding(.top, 4)
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
                        .font(.buttonFontSmall)
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
                        .font(.buttonFontSmall)
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
                        .font(.bodyFont)
                        .foregroundColor(Color.primaryDark)
                    
                    // 예시 텍스트 (모국어 설정에서만 표시)
                    if showSampleText {
                        Text(sampleText)
                            .font(.bodyFontSmall)
                            .foregroundColor(Color.primaryDark.opacity(0.5))
                            .lineLimit(1)
                    } else {
                        Text(correctionSampleText)
                            .font(.bodyFontSmall)
                            .foregroundColor(Color.primaryDark.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // 선택 표시
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.primaryDark)
                        .font(.title2)
                }
            }
            .padding(16)
            .background(isSelected ? Color.primaryYellow.opacity(0.1) : Color.gray.opacity(0.05))
            .overlay(
                Rectangle()
                    .stroke(isSelected ? Color.primaryDark : Color.clear, lineWidth: 2)
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
        case "es":
            return "Escribir diario de hoy"
        case "th":
            return "เขียนไดอารี่วันนี้"
        case "de":
            return "Heutiges Tagebuch schreiben"
        case "zh":
            return "写今天的日记"
        case "ar":
            return "كتابة يوميات اليوم"
        case "fr":
            return "Écrire le journal d'aujourd'hui"
        case "it":
            return "Scrivi il diario di oggi"
        case "pt":
            return "Escrever diário de hoje"
        case "hi":
            return "आज की डायरी लिखें"
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
        case "es":
            return "Escribir diario en español"
        case "th":
            return "เขียนไดอารี่เป็นภาษาไทย"
        case "de":
            return "Tagebuch auf Deutsch schreiben"
        case "zh":
            return "用中文写日记"
        case "ar":
            return "كتابة يوميات بالعربية"
        case "fr":
            return "Écrire journal en français"
        case "it":
            return "Scrivi diario in italiano"
        case "pt":
            return "Escrever diário em português"
        case "hi":
            return "हिन्दी में डायरी लिखें"
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
