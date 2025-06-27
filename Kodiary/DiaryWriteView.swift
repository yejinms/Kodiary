import SwiftUI

struct DiaryWriteView: View {
    @State private var diaryText = ""
    @Binding var navigationPath: NavigationPath
    let editData: DiaryEditData? // 🆕 수정 모드 지원
    init(navigationPath: Binding<NavigationPath>, editData: DiaryEditData? = nil) {
            self._navigationPath = navigationPath
            self.editData = editData
        }
    
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var userManager: UserManager // 🆕 추가
    @StateObject private var apiManager = APIManager.shared
    
    @State private var showingLoading = false
    @State private var showingError = false
    @FocusState private var isTextEditorFocused: Bool
    
    // 수정 모드인지 확인
    private var isEditMode: Bool {
        return editData != nil
    }

    // 수정 모드에서 원본 일기
    private var originalDiary: DiaryEntry? {
        return editData?.originalDiary
    }
    
    // 글자 수 제한 상수
    private let maxCharacterCount = 160
    
    // 글자 수 초과 여부 계산 (161자부터 빨간색)
    private var isOverCharacterLimit: Bool {
        diaryText.count > maxCharacterCount
    }
    
    // 첨삭 버튼 활성화 여부 (1자 이상 160자 이하일 때만 활성화)
    private var isAnalyzeButtonEnabled: Bool {
        !diaryText.isEmpty && diaryText.count <= maxCharacterCount && !showingLoading
    }
    
    // ContentView와 동일한 날짜 관련 computed properties
    var todayDateComponents: (year: String, month: String, weekday: String) {
        let today = Date()
        let components = languageManager.currentLanguage.dateComponents
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        
        formatter.dateFormat = components.year
        let year = formatter.string(from: today)
        
        formatter.dateFormat = components.month
        let month = formatter.string(from: today)
        
        formatter.dateFormat = components.weekday
        let weekday = formatter.string(from: today)
        
        return (year, month, weekday)
    }
    
    var todayDayString: String {
        let today = Date()
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        formatter.dateFormat = languageManager.currentLanguage.dayDateFormat
        return formatter.string(from: today)
    }
    
    var body: some View {
        ZStack {
            // 전체 영역 탭해서 키보드 내리기
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextEditorFocused = false
                }
            
            VStack {
                Spacer()
                    .frame(height: 26)
                // ContentView와 동일한 날짜 헤더
                ResponsiveDateHeader(dateComponents: todayDateComponents)
                    .onTapGesture {
                        isTextEditorFocused = false
                    }
                
                VStack(spacing: 10) {
                    // ContentView와 동일한 원형 날짜 표시
                    ZStack {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: 265.5, height: 265.5)
                            .cornerRadius(265.5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 265.5)
                                    .inset(by: 0.9)
                                    .stroke(Color.primaryDark, lineWidth: 1.8)
                            )
                        
                        VStack(spacing: Spacing.sm) {
                            Text(todayDayString)
                                .font(.titleHuge)
                                .foregroundColor(.primaryDark)
                        }
                    }
                    .padding(.top, 10)
                    .onTapGesture {
                        isTextEditorFocused = false
                    }
                    
                    // 첨삭 언어 표시
                    HStack {
                        HStack{
                            Image(systemName: "pencil.line")
                                .font(.buttonFontSmall)
                                .foregroundColor(.primaryDark)
                            Text(getCorrectionLanguageText())
                                .font(.buttonFontSmall)
                                .foregroundColor(.primaryDark)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(1)
                        .background(Color.primaryYellow.opacity(0.5))
                        Spacer()
                        // 글자 수 표시 - 160자 초과 시 빨간색
                        HStack {
                            Spacer()
                            Text(languageManager.currentLanguage.characterCount(diaryText.count, maxCharacterCount))
                                .font(.buttonFontSmall)
                                .foregroundColor(isOverCharacterLimit ? .secondaryRed : .gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    .padding(.leading, 20)
                    .onTapGesture {
                        isTextEditorFocused = false
                    }
                    
                    // 줄 노트 스타일 및 폰트 스타일
                    ZStack(alignment: .topLeading) {
                        // 배경
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 230)
                        
                        // 줄 노트처럼 선들 추가
                        VStack(spacing: 34) {
                            ForEach(0..<6, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.primaryDark.opacity(0.4))
                                    .frame(height: 1)
                            }
                        }
                        .padding(.top, 38)
                        .padding(.horizontal, 10)
                        
                        TextEditor(text: $diaryText)
                            .font(.handWrite)
                            .foregroundColor(isOverCharacterLimit ? .secondaryRed : .primary)
                            .frame(minHeight: 230)
                            .padding(5)
                            .background(Color.clear)
                            .disabled(showingLoading)
                            .scrollContentBackground(.hidden)
                            .lineSpacing(17)
                            .focused($isTextEditorFocused)
                            .onChange(of: diaryText) { newValue in
                                // 161자 이상 입력 시 161자에서 멈춤 (161자까지는 허용해서 빨간색 표시)
                                if newValue.count > maxCharacterCount + 1 {
                                    diaryText = String(newValue.prefix(maxCharacterCount + 1))
                                }
                            }
                        
                        // Placeholder 텍스트 (첨삭 언어에 따라 변경)
                        if diaryText.isEmpty {
                            Text(getCorrectionPlaceholder())
                                .font(.handWrite)
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.horizontal, 15)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, 25)
                    
                    // 첨삭 버튼
                    Button(action: {
                        isTextEditorFocused = false // 키보드 내리기
                        Task {
                            await analyzeWithAI()
                        }
                    }) {
                        Text(languageManager.currentLanguage.analyzeDiaryButton)
                            .font(.buttonFont)
                            .foregroundColor(.primaryDark)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: 350, height: 50)
                    .background(isAnalyzeButtonEnabled ? Color.primaryBlue : Color.primaryDark.opacity(0.2))
                    .disabled(!isAnalyzeButtonEnabled)
                    Spacer()
                }
            }
            .offset(y: isTextEditorFocused ? -130 : 0) // 키보드가 올라오면 전체 화면을 위로 이동
            .animation(.easeInOut(duration: 0.3), value: isTextEditorFocused)
            
            // 로딩 오버레이
            if showingLoading {
                LoadingView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // 커스텀 백버튼 (좌측)
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    navigationPath.removeLast()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.primaryDark.opacity(0.5))
                }
            }
        }
        .navigationDestination(for: CorrectionData.self) { correctionData in
            CorrectionResultView(
                originalText: correctionData.originalText,
                corrections: correctionData.corrections,
                navigationPath: $navigationPath,
                isEditMode: correctionData.isEditMode,
                originalDiary: correctionData.originalDiary
            )
            .environmentObject(dataManager)
            .environmentObject(languageManager)
            .environmentObject(userManager)
        }
        .alert(languageManager.currentLanguage.errorTitle, isPresented: $showingError) {
            Button(languageManager.currentLanguage.confirmButton) { }
            Button(languageManager.currentLanguage.retryButton) {
                Task { await analyzeWithAI() }
            }
        } message: {
            Text(apiManager.errorMessage ?? languageManager.currentLanguage.unknownErrorMessage)
        }
        .onAppear {
            // 수정 모드일 때 기존 텍스트 로드
            if let editData = editData {
                diaryText = editData.originalText
                print("🔄 수정 모드로 진입: \(editData.originalText.prefix(50))...")
            }
        }
    }
    
    // 첨삭 언어 표시 텍스트 (LanguageManager 사용)
    func getCorrectionLanguageText() -> String {
        let correctionLanguageName = languageManager.nativeLanguage.languageNameTranslations[languageManager.correctionLanguage.languageCode] ?? languageManager.correctionLanguage.languageName
        
        return languageManager.currentLanguage.writeInLanguageText(correctionLanguageName)
    }
    
    // 첨삭 언어에 따른 placeholder (LanguageManager 사용)
    func getCorrectionPlaceholder() -> String {
        return languageManager.correctionLanguage.correctionLanguagePlaceholder
    }
    
    // AI 첨삭 분석 (다국어 지원)
    func analyzeWithAI() async {
        showingLoading = true
        let startTime = Date()
        
        do {
            print("🤖 AI 첨삭 요청 시작: \(diaryText.prefix(50))...")
            print("📝 첨삭 언어: \(languageManager.correctionLanguage.languageName)")
            print("🌍 설명 언어: \(languageManager.nativeLanguage.languageName)")
            print("🔄 수정 모드: \(isEditMode)")
            
            // 새로운 다국어 지원 API 호출
            let corrections = try await apiManager.analyzeDiary(
                text: diaryText,
                correctionLanguage: languageManager.correctionLanguageCode,
                explanationLanguage: languageManager.nativeLanguageCode
            )
            
            // 최소 1초 대기
            let elapsedTime = Date().timeIntervalSince(startTime)
            if elapsedTime < 1 {
                try await Task.sleep(nanoseconds: UInt64((2.0 - elapsedTime) * 1_000_000_000))
            }
            
            print("✅ AI 첨삭 완료: \(corrections.count)개 수정점")
            
            let correctionData = CorrectionData(
                originalText: diaryText,
                corrections: corrections,
                isEditMode: isEditMode,
                originalDiary: originalDiary
            )
            
            await MainActor.run {
                showingLoading = false
                navigationPath.append(correctionData)
            }
            
        } catch {
            print("❌ AI 첨삭 에러: \(error)")
            
            await MainActor.run {
                showingLoading = false
                showingError = true
            }
        }
    }
}
