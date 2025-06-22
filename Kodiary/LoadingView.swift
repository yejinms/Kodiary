//
//  LoadingView.swift
//  Kodiary
//
//  Created by Niko on 6/20/25.
//

import SwiftUI

struct LoadingView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // 전체 화면 배경
            Color.background
                .ignoresSafeArea(.all)
            
            // 중앙 로딩 컨텐츠
            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 12) {
                    Text(languageManager.currentLanguage.loadingMessage)
                        .font(.titleSmall1)
                        .foregroundColor(.primaryDark)
                        .multilineTextAlignment(.center)
                    
                    Text(languageManager.currentLanguage.loadingSubMessage)
                        .font(.titleSmall2)
                        .foregroundColor(.primaryDark)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 20)
                // SwiftUI 로딩 애니메이션
                ZStack {
                    Circle()
                        .stroke(Color.primaryDark.opacity(0.1), lineWidth: 6)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.primaryDark, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotationAngle))
                    
                    Image(systemName: "text.quote")
                        .foregroundColor(Color.primaryDark)
                        .font(.largeTitle)
                }
                .padding(.bottom, 100)
                .onAppear {
                    withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }
                Spacer()
            }
            .padding(40)
        }
    }
}


struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
            .environmentObject(DataManager.shared)
            .environmentObject(LanguageManager.shared)
    }
}
