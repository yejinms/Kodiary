//
//  ContentView.swift
//  Kodiary
//
//  Created by Niko on 6/19/25.
//

import SwiftUI

struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    @EnvironmentObject var dataManager: DataManager
    
    // 오늘 일기 작성 여부 확인
    var hasTodayDiary: Bool {
        let today = Date()
        return dataManager.getDiary(for: today) != nil
    }
    
    // 사용자 이름 (실제로는 UserDefaults나 다른 곳에서 가져올 수 있음)
    var username: String {
        return "사용자" // 나중에 실제 사용자 이름으로 변경 가능
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: Spacing.xl) {
                ZStack{
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .frame(width: 265.5, height: 265.5)
                                    .cornerRadius(265.5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 265.5)
                                            .inset(by: 0.9)
                                            .stroke(Color.primaryDark, lineWidth: 1.8)
                                    )
                                Text("5")
                                    .font(.titleHuge)
                                    .foregroundColor(.primaryDark)
                            }
                
                // 인사말 (조건부)
                VStack(spacing: Spacing.sm) {
                    if hasTodayDiary {
                        Text("안녕 \(username)!")
                            .font(.bodyFont)
                            .foregroundColor(.primaryDark)
                        Text("멋진 하루 보내세요! 🌟")
                            .font(.bodyFont)
                            .foregroundColor(.primaryDark)
                    } else {
                        Text("안녕 \(username)!")
                            .font(.bodyFont)
                            .foregroundColor(.primaryDark)
                        Text("오늘은 어떤 하루를 보냈나요? ✨")
                            .font(.bodyFont)
                            .foregroundColor(.primaryDark)
                    }
                }
                .padding(Spacing.md)
                .background(Color.background)
                .cornerRadius(CornerRadius.md)
                
                Spacer()
                
                // 일기 쓰기 버튼 (조건부 텍스트)
                Button(action: {
                    navigationPath.append("diary-write")
                }) {
                    HStack(spacing: Spacing.sm) {
                        Text(hasTodayDiary ? "또 다른 일기 쓰기" : "일기 쓰기")
                            .font(.buttonFont)
                        Image(systemName: "pencil")
                            .font(.buttonFont)
                    }
                    .foregroundColor(.primaryDark)
                    .frame(width: 220, height: 50)
                    .background(Color.background)
                    .cornerRadius(CornerRadius.md)
                }
                
                // 히스토리 버튼
                Button("일기 히스토리") {
                    navigationPath.append("diary-history")
                }
                .font(.bodyFont)
                .foregroundColor(.primaryDark)
                
                Spacer()
            }
            .padding(Spacing.md)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "diary-write":
                    DiaryWriteView(
                        navigationPath: $navigationPath
                    )
                case "diary-history":
                    DiaryHistoryView()
                default:
                    Text("Unknown destination")
                }
            }
        }
        .onAppear {
            // 앱 시작 시 데이터 새로고침
            dataManager.fetchDiaries()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DataManager.shared)
    }
}
