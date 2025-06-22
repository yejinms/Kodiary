import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("언어 선택 / Language / 言語")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("Choose your preferred language")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    ForEach(Array(LanguageManager.availableLanguages.enumerated()), id: \.offset) { index, language in
                        LanguageCard(
                            language: language,
                            isSelected: language.locale.identifier == languageManager.currentLanguage.locale.identifier
                        ) {
                            languageManager.setLanguage(language)
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LanguageCard: View {
    let language: LanguageTexts
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 국기
                Text(language.flag)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 4) {
                    // 언어 이름
                    Text(languageName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    // 예시 텍스트
                    Text(sampleText)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 선택 표시
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var languageName: String {
        switch language.locale.identifier {
        case "ko_KR":
            return "한국어"
        case "en_US":
            return "English"
        case "ja_JP":
            return "日本語"
        default:
            return "Unknown"
        }
    }
    
    var sampleText: String {
        switch language.locale.identifier {
        case "ko_KR":
            return "오늘의 일기 쓰기"
        case "en_US":
            return "Write Today's Diary"
        case "ja_JP":
            return "今日の日記を書く"
        default:
            return "Sample text"
        }
    }
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView()
            .environmentObject(LanguageManager.shared)
    }
}
