//
//  LanguageSelectionView.swift
//  Kodiary
//
//  Created by Niko on 6/22/25.
//

import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 헤더
                VStack(spacing: 8) {
                    Text("🌍")
                        .font(.largeTitle)
                    Text("언어 선택")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("일기를 작성할 언어를 선택해주세요")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 언어 옵션들
                VStack(spacing: 12) {
                    ForEach(SupportedLanguage.allCases) { language in
                        LanguageOptionRow(
                            language: language,
                            isSelected: languageManager.currentLanguage == language
                        ) {
                            languageManager.setLanguage(language)
                            
                            // 선택 후 잠시 대기한 다음 모달 닫기
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                dismiss()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 취소 버튼
                Button("취소") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }
}

struct LanguageOptionRow: View {
    let language: SupportedLanguage
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 국기
                Text(language.flag)
                    .font(.title)
                
                // 언어명
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    // 샘플 텍스트
                    Text(sampleText)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 선택 표시
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.3))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    var sampleText: String {
        switch language {
        case .korean:
            return "일기 쓰기"
        case .english:
            return "Write Diary"
        case .spanish:
            return "Escribir Diario"
        }
    }
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView()
            .environmentObject(LanguageManager.shared)
    }
}
