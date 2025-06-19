//
//  LoadingView.swift
//  Kodiary
//
//  Created by Niko on 6/20/25.
//

import SwiftUI

struct LoadingView: View {
    @State private var progress: Double = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
                
                Text("🤖")
                    .font(.title)
            }
            
            VStack(spacing: 8) {
                Text("AI 첨삭 중...")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("잠시만 기다려주세요")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 10)
        .onAppear {
            withAnimation(.linear(duration: 5)) {
                progress = 1.0
            }
        }
    }
}
