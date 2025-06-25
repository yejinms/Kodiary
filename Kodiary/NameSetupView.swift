import SwiftUI

struct NameSetupView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var languageManager: LanguageManager
    @State private var userName = ""
    @State private var isLoading = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 환영 메시지
            VStack(spacing: 20) {
                // 앱 아이콘
                ZStack {
                    Circle()
                        .fill(Color.primaryYellow)
                        .frame(width: 100, height: 100)
                        .shadow(color: .primaryDark.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Text("👋")
                        .font(.system(size: 50))
                }
                
                VStack(spacing: 12) {
                    Text(getWelcomeTitle())
                        .font(.titleLarge)
                        .foregroundColor(.primaryDark)
                        .multilineTextAlignment(.center)
                    
                    Text(getWelcomeSubtitle())
                        .font(.bodyFont)
                        .foregroundColor(.primaryDark.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(5)
                }
            }
            
            Spacer()
            
            // 이름 입력 섹션
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text(getNamePrompt())
                        .font(.bodyFontTitle)
                        .foregroundColor(.primaryDark)
                    
                    // 이름 입력 필드
                    TextField(getNamePlaceholder(), text: $userName)
                        .font(.titleLarge)
                        .foregroundColor(.primaryDark)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .focused($isTextFieldFocused)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .onSubmit {
                            if canProceed {
                                completeSetup()
                            }
                        }
                }
                .padding(.horizontal, 40)
                
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
                            Text(getContinueButtonText())
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
            }
            
            Spacer()
        }
        .background(Color.background)
        .onAppear {
            // 화면이 나타나면 자동으로 키보드 포커스
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .onTapGesture {
            // 화면 탭하면 키보드 내리기
            isTextFieldFocused = false
        }
    }
    
    // MARK: - Computed Properties
    private var canProceed: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    private func completeSetup() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        isLoading = true
        isTextFieldFocused = false
        
        // 이름만 저장하고 언어 설정으로 이동
        userManager.updateUserName(trimmedName)
        userManager.proceedToLanguageSetup()
        
        // 로딩 애니메이션을 위한 딜레이
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }
    
    // MARK: - Localized Strings
    private func getWelcomeTitle() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko": return "환영합니다!"
        case "en": return "Welcome!"
        case "ja": return "ようこそ！"
        case "es": return "¡Bienvenido!"
        case "th": return "ยินดีต้อนรับ!"
        case "de": return "Willkommen!"
        case "zh": return "欢迎！"
        case "ar": return "مرحباً!"
        case "fr": return "Bienvenue!"
        case "it": return "Benvenuto!"
        case "pt": return "Bem-vindo!"
        case "hi": return "स्वागत है!"
        default: return "Welcome!"
        }
    }
    
    private func getWelcomeSubtitle() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko": return "Kodiary와 함께 언어 학습 여정을 시작해보세요"
        case "en": return "Start your language learning journey with Kodiary"
        case "ja": return "Kodiaryと一緒に言語学習の旅を始めましょう"
        case "es": return "Comienza tu viaje de aprendizaje de idiomas con Kodiary"
        case "th": return "เริ่มต้นการเรียนรู้ภาษากับ Kodiary"
        case "de": return "Beginnen Sie Ihre Sprachlernreise mit Kodiary"
        case "zh": return "与 Kodiary 一起开始您的语言学习之旅"
        case "ar": return "ابدأ رحلة تعلم اللغة مع Kodiary"
        case "fr": return "Commencez votre voyage d'apprentissage des langues avec Kodiary"
        case "it": return "Inizia il tuo viaggio di apprendimento linguistico con Kodiary"
        case "pt": return "Comece sua jornada de aprendizado de idiomas com Kodiary"
        case "hi": return "Kodiary के साथ अपनी भाषा सीखने की यात्रा शुरू करें"
        default: return "Start your language learning journey with Kodiary"
        }
    }
    
    private func getNamePrompt() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko": return "어떻게 불러드릴까요?"
        case "en": return "What should we call you?"
        case "ja": return "何とお呼びしましょうか？"
        case "es": return "¿Cómo te llamamos?"
        case "th": return "เราจะเรียกคุณว่าอะไรดี?"
        case "de": return "Wie sollen wir Sie nennen?"
        case "zh": return "我们应该怎么称呼您？"
        case "ar": return "ماذا يجب أن نناديك؟"
        case "fr": return "Comment devons-nous vous appeler?"
        case "it": return "Come dovremmo chiamarti?"
        case "pt": return "Como devemos te chamar?"
        case "hi": return "हमें आपको क्या कहना चाहिए?"
        default: return "What should we call you?"
        }
    }
    
    private func getNamePlaceholder() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko": return "이름을 입력하세요"
        case "en": return "Enter your name"
        case "ja": return "お名前を入力してください"
        case "es": return "Ingresa tu nombre"
        case "th": return "ใส่ชื่อของคุณ"
        case "de": return "Geben Sie Ihren Namen ein"
        case "zh": return "输入您的姓名"
        case "ar": return "أدخل اسمك"
        case "fr": return "Entrez votre nom"
        case "it": return "Inserisci il tuo nome"
        case "pt": return "Digite seu nome"
        case "hi": return "अपना नाम दर्ज करें"
        default: return "Enter your name"
        }
    }
    
    private func getContinueButtonText() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko": return "시작하기"
        case "en": return "Get Started"
        case "ja": return "始める"
        case "es": return "Comenzar"
        case "th": return "เริ่มต้น"
        case "de": return "Loslegen"
        case "zh": return "开始"
        case "ar": return "ابدأ"
        case "fr": return "Commencer"
        case "it": return "Inizia"
        case "pt": return "Começar"
        case "hi": return "शुरू करें"
        default: return "Get Started"
        }
    }
    
    private func getSkipButtonText() -> String {
        switch languageManager.currentLanguage.languageCode {
        case "ko": return "나중에 설정하기"
        case "en": return "Set up later"
        case "ja": return "後で設定する"
        case "es": return "Configurar más tarde"
        case "th": return "ตั้งค่าภายหลัง"
        case "de": return "Später einrichten"
        case "zh": return "稍后设置"
        case "ar": return "الإعداد لاحقاً"
        case "fr": return "Configurer plus tard"
        case "it": return "Configura più tardi"
        case "pt": return "Configurar mais tarde"
        case "hi": return "बाद में सेट करें"
        default: return "Set up later"
        }
    }
}

struct NameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NameSetupView()
            .environmentObject(UserManager.shared)
            .environmentObject(LanguageManager.shared)
    }
}
