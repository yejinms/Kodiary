import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더
                VStack(spacing: 12) {
                    Text("📖")
                        .font(.system(size: 60))
                    
                    Text(languageManager.currentLanguage.helpTitle)
                        .font(.titleLarge)
                        .foregroundColor(.primaryDark)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                    
                    Text(getWelcomeMessage())
                        .font(.bodyFont)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                        .lineSpacing(10)
                        .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                
                // 사용법 가이드
                VStack(alignment: .leading, spacing: 20) {
                    Text(getHowToUseTitle())
                        .font(.titleLarge)
                        .foregroundColor(.primaryDark)
                    
                    // Step 1: 언어 설정
                    HelpStepView(
                        stepNumber: "1",
                        title: getStep1Title(),
                        description: getStep1Description(),
                        color: .primaryBlue
                    )
                    
                    // Step 2: 일기 쓰기
                    HelpStepView(
                        stepNumber: "2",
                        title: getStep2Title(),
                        description: getStep2Description(),
                        color: .primaryYellow
                    )
                    
                    // Step 3: 첨삭 받기
                    HelpStepView(
                        stepNumber: "3",
                        title: getStep3Title(),
                        description: getStep3Description(),
                        color: .secondaryTeal
                    )
                }
                .padding(.horizontal, 20)
                
                // 추가 팁
                VStack(alignment: .leading, spacing: 16) {
                    Text(getTipsTitle())
                        .font(.titleLarge)
                        .foregroundColor(.primaryDark)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        TipItemView(
                            icon: "lightbulb",
                            text: getTip1()
                        )
                        
                        TipItemView(
                            icon: "calendar",
                            text: getTip2()
                        )
                        
                        TipItemView(
                            icon: "star",
                            text: getTip3()
                        )
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // 문의하기 섹션
                VStack(alignment: .leading, spacing: 20) {
                    Text(getContactTitle())
                        .font(.titleLarge)
                        .foregroundColor(.primaryDark)
                    
                    Text(getContactDescription())
                        .font(.bodyFont)
                        .foregroundColor(.gray)
                        .lineSpacing(6)
                    
                    // 이메일 버튼
                    Button(action: {
                        sendEmail()
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                                .font(.system(size: 18))
                            Text(getEmailButtonText())
                                .font(.buttonFont)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.primaryDark)
                        .cornerRadius(12)
                    }
                    
                    // 앱 정보
                    VStack(alignment: .leading, spacing: 8) {
                        Text(getAppInfoTitle())
                            .font(.buttonFontSmall)
                            .foregroundColor(.gray)
                        
                        Text("Kodiary v1.0")
                            .font(.buttonFontSmall)
                            .foregroundColor(.gray)
                        
                        Text("© 2025 Poplarplanet")
                            .font(.buttonFontSmall)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 30)
                }
                .padding(.horizontal, 20)
                .lineSpacing(10)
                .padding(.top, 20)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
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
    }
    
    // MARK: - 언어별 텍스트
    
    func getWelcomeMessage() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "Kodiary와 함께 매일 외국어 일기를 쓰고 AI 첨삭을 받아보세요!"
        case "en":
            return "Write daily foreign language diaries with Kodiary and get AI corrections!"
        case "ja":
            return "Kodiaryと一緒に毎日外国語の日記を書いてAI添削を受けてみてください！"
        default:
            return "Write daily foreign language diaries with Kodiary and get AI corrections!"
        }
    }
    
    func getHowToUseTitle() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "🚀 사용법"
        case "en":
            return "🚀 How to Use"
        case "ja":
            return "🚀 使い方"
        default:
            return "🚀 How to Use"
        }
    }
    
    func getStep1Title() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "첨삭 언어 설정"
        case "en":
            return "Set Correction Language"
        case "ja":
            return "添削言語の設定"
        default:
            return "Set Correction Language"
        }
    }
    
    func getStep1Description() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "메인 화면 좌상단의 국기 버튼을 눌러 학습하고 싶은 언어를 선택하세요. 영어, 일본어, 스페인어 등 12개 언어를 지원합니다."
        case "en":
            return "Tap the flag button in the top-left corner of the main screen to select the language you want to learn. We support 12 languages including English, Japanese, and Spanish."
        case "ja":
            return "メイン画面の左上にある国旗ボタンを押して、学習したい言語を選択してください。英語、日本語、スペイン語など12言語をサポートしています。"
        default:
            return "Tap the flag button in the top-left corner of the main screen to select the language you want to learn. We support 12 languages including English, Japanese, and Spanish."
        }
    }
    
    func getStep2Title() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "매일 일기 쓰기"
        case "en":
            return "Write Daily Diary"
        case "ja":
            return "毎日日記を書く"
        default:
            return "Write Daily Diary"
        }
    }
    
    func getStep2Description() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "선택한 언어로 오늘 있었던 일을 자유롭게 써보세요. 160자 이내로 작성하면 됩니다. 완벽하지 않아도 괜찮아요!"
        case "en":
            return "Write freely about what happened today in your chosen language. Keep it within 160 characters. It doesn't have to be perfect!"
        case "ja":
            return "選択した言語で今日あったことを自由に書いてみてください。160文字以内で作成すれば大丈夫です。完璧でなくても構いません！"
        default:
            return "Write freely about what happened today in your chosen language. Keep it within 160 characters. It doesn't have to be perfect!"
        }
    }
    
    func getStep3Title() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "AI 첨삭 받기"
        case "en":
            return "Get AI Corrections"
        case "ja":
            return "AI添削を受ける"
        default:
            return "Get AI Corrections"
        }
    }
    
    func getStep3Description() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "'첨삭 받기' 버튼을 누르면 AI가 문법, 어휘, 표현을 자세히 분석해서 더 자연스러운 표현을 제안해드립니다. 설명도 함께 제공됩니다."
        case "en":
            return "Tap the 'Get Corrections' button and AI will analyze grammar, vocabulary, and expressions in detail, suggesting more natural expressions with explanations."
        case "ja":
            return "'添削を受ける'ボタンを押すと、AIが文法、語彙、表現を詳しく分析して、より自然な表現を提案してくれます。説明も一緒に提供されます。"
        default:
            return "Tap the 'Get Corrections' button and AI will analyze grammar, vocabulary, and expressions in detail, suggesting more natural expressions with explanations."
        }
    }
    
    func getTipsTitle() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "💡 활용 팁"
        case "en":
            return "💡 Tips"
        case "ja":
            return "💡 活用のコツ"
        default:
            return "💡 Tips"
        }
    }
    
    func getTip1() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "매일 조금씩이라도 꾸준히 쓰는 것이 중요해요. 습관이 되면 자연스럽게 실력이 늘어납니다."
        case "en":
            return "Consistency is key - even writing a little bit every day helps. Once it becomes a habit, your skills will naturally improve."
        case "ja":
            return "毎日少しずつでも継続して書くことが大切です。習慣になれば自然と実力が向上します。"
        default:
            return "Consistency is key - even writing a little bit every day helps. Once it becomes a habit, your skills will naturally improve."
        }
    }
    
    func getTip2() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "히스토리에서 과거 일기를 다시 보면서 실력 향상을 확인해보세요."
        case "en":
            return "Check your progress by reviewing past diary entries in the history section."
        case "ja":
            return "履歴で過去の日記を見直して、実力向上を確認してみてください。"
        default:
            return "Check your progress by reviewing past diary entries in the history section."
        }
    }
    
    func getTip3() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "첨삭 결과를 꼼꼼히 읽어보고 같은 실수를 반복하지 않도록 주의해보세요."
        case "en":
            return "Read the correction results carefully to avoid repeating the same mistakes."
        case "ja":
            return "添削結果をじっくり読んで、同じ間違いを繰り返さないよう注意してみてください。"
        default:
            return "Read the correction results carefully to avoid repeating the same mistakes."
        }
    }
    
    func getContactTitle() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "📧 문의하기"
        case "en":
            return "📧 Contact Us"
        case "ja":
            return "📧 お問い合わせ"
        default:
            return "📧 Contact Us"
        }
    }
    
    func getContactDescription() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "궁금한 점이나 개선 사항이 있으시면 언제든 연락해주세요. 여러분의 소중한 의견이 Kodiary를 더 좋게 만듭니다."
        case "en":
            return "If you have any questions or suggestions for improvement, please don't hesitate to contact us. Your valuable feedback helps make Kodiary better."
        case "ja":
            return "ご質問や改善点がございましたら、いつでもお気軽にご連絡ください。皆様の貴重なご意見がKodiaryをより良くします。"
        default:
            return "If you have any questions or suggestions for improvement, please don't hesitate to contact us. Your valuable feedback helps make Kodiary better."
        }
    }
    
    func getEmailButtonText() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "poplarplanet@gmail.com"
        case "en":
            return "poplarplanet@gmail.com"
        case "ja":
            return "poplarplanet@gmail.com"
        default:
            return "poplarplanet@gmail.com"
        }
    }
    
    func getAppInfoTitle() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "앱 정보"
        case "en":
            return "App Info"
        case "ja":
            return "アプリ情報"
        default:
            return "App Info"
        }
    }
    
    // MARK: - Actions
    
    func sendEmail() {
        let email = "poplarplanet@gmail.com"
        let subject = getEmailSubject()
        let body = getEmailBody()
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
    
    func getEmailSubject() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return "Kodiary 문의사항"
        case "en":
            return "Kodiary Inquiry"
        case "ja":
            return "Kodiaryお問い合わせ"
        default:
            return "Kodiary Inquiry"
        }
    }
    
    func getEmailBody() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko":
            return """
            안녕하세요, Kodiary 팀입니다.
            
            문의사항을 작성해주세요:
            
            
            ---
            앱 버전: 1.0
            기기: \(UIDevice.current.model)
            OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
            """
        case "en":
            return """
            Hello Kodiary Team,
            
            Please write your inquiry:
            
            
            ---
            App Version: 1.0
            Device: \(UIDevice.current.model)
            OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
            """
        case "ja":
            return """
            こんにちは、Kodiaryチームです。
            
            お問い合わせ内容をご記入ください：
            
            
            ---
            アプリバージョン: 1.0
            デバイス: \(UIDevice.current.model)
            OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
            """
        default:
            return """
            Hello Kodiary Team,
            
            Please write your inquiry:
            
            
            ---
            App Version: 1.0
            Device: \(UIDevice.current.model)
            OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
            """
        }
    }
}

// MARK: - 서브 컴포넌트들

struct HelpStepView: View {
    let stepNumber: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 단계 번호
            ZStack {
                Circle()
                    .fill(color.opacity(0.6))
                    .frame(width: 40, height: 40)
                
                Text(stepNumber)
                    .font(.titleLarge)
                    .foregroundColor(Color.primaryDark)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.titleSmall2)
                        .foregroundColor(.primaryDark)
                        .padding(.bottom, 4)
                }
                
                Text(description)
                    .font(.bodyFontSmall)
                    .foregroundColor(.gray)
                    .lineSpacing(6)
            }
            .frame(maxWidth: .infinity, alignment: .leading) //가로 꽉 채우기
        }
        .frame(maxWidth: .infinity) // 가로 꽉 채우기
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct TipItemView: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.bodyFontSmall)
                .foregroundColor(.secondaryTeal)
                .frame(width: 20)
            
            Text(text)
                .font(.bodyFontSmall)
                .foregroundColor(.gray)
                .lineSpacing(6)
        }
        .padding(.top, 10)
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HelpView()
                .environmentObject(LanguageManager.shared)
                .environmentObject(UserManager.shared)
        }
    }
}
