import SwiftUI

struct SaveLoadingView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var waveProgress: CGFloat = 0
    @State private var waveOffset: CGFloat = 0
    
    var todayDayString: String {
        let today = Date()
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        formatter.dateFormat = languageManager.currentLanguage.dayDateFormat
        return formatter.string(from: today)
    }
    
    var body: some View {
        ZStack {
            // 전체 화면 배경
            Color.background
                .ignoresSafeArea(.all)
            
            // 중앙 로딩 컨텐츠
            VStack(spacing: 24) {
                Spacer()
                
                // 원형 날짜 표시 (물결 애니메이션 포함)
                ZStack {
                    // 기본 원형 테두리
                    Circle()
                        .stroke(Color.primaryDark, lineWidth: 1.8)
                        .frame(width: 265.5, height: 265.5)
                    
                    // 물결 채우기 애니메이션
                    WaveShape(progress: waveProgress, waveHeight: 15, offset: waveOffset)
                        .fill(Color.primaryDark)
                        .frame(width: 265.5, height: 265.5)
                        .clipShape(Circle())
                    
                    // 날짜 텍스트 (항상 최상단)
                    VStack(spacing: Spacing.sm) {
                        Text(todayDayString)
                            .font(.titleHuge)
                            .foregroundColor(.background)
                    }
                }
                .onAppear {
                    // 0.2초 지연 후 물결 채우기 애니메이션 시작 (2초)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 2.0)) {
                            waveProgress = 1.0
                        }
                    }
                    
                    // 물결 움직임 애니메이션 (더 자연스럽고 느리게)
                    withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                        waveOffset = 2 * .pi
                    }
                }
                
                // 저장 메시지
                VStack(spacing: 12) {
                    Text(languageManager.currentLanguage.savingMessage)
                        .font(.titleSmall1)
                        .foregroundColor(.primaryDark)
                        .multilineTextAlignment(.center)
                    
                    Text(languageManager.currentLanguage.savingSubMessage)
                        .font(.titleSmall2)
                        .foregroundColor(.primaryDark)
                        .multilineTextAlignment(.center)
                        .lineSpacing(10)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                .padding(.bottom, 97)
                
                Spacer()
            }
        }
    }
}

#Preview {
    SaveLoadingView()
        .environmentObject(LanguageManager.shared)
}

// 물결 모양을 그리는 Shape
struct WaveShape: Shape {
    var progress: CGFloat
    var waveHeight: CGFloat
    var offset: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(progress, offset) }
        set {
            progress = newValue.first
            offset = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // progress가 0이면 빈 path 반환
        guard progress > 0 else { return path }
        
        // 채워질 높이 계산 (바닥부터 차오름)
        let fillHeight = height * progress
        let waterLevel = height - fillHeight  // 물의 상단 레벨
        
        // 물결 상단 라인 그리기
        path.move(to: CGPoint(x: 0, y: waterLevel))
        
        // 물결 곡선 그리기 (상단 라인)
        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            let sine = sin(relativeX * 4 * .pi + offset)
            let waveY = waterLevel + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: waveY))
        }
        
        // 우측 하단으로 이동
        path.addLine(to: CGPoint(x: width, y: height))
        // 좌측 하단으로 이동
        path.addLine(to: CGPoint(x: 0, y: height))
        // 시작점으로 돌아가기
        path.closeSubpath()
        
        return path
    }
}
