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
    
    // 오늘 날짜 포맷팅
    var todayDateString: String {
        let today = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy     M월     EEEE"
        return formatter.string(from: today)
    }
    
    var todayDayString: String {
        let today = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "d"
        return formatter.string(from: today)
    }
    
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: Spacing.lg) {
                
                ZStack{
                    Rectangle()
                        .frame(width: 500, height: 70)
                        .ignoresSafeArea()
                        .foregroundColor(.clear)
                        .overlay(
                            Rectangle()
                                .inset(by: 0.9)
                                .stroke(Color.primaryDark.opacity(0.2), lineWidth: 1.8)
                        )
                        
                    
                    Text(todayDateString)
                        .font(.titleLarge)
                        .foregroundColor(.primaryDark)
                        .multilineTextAlignment(.center)
                }
        
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
                
                // 인사말 (조건부)
                VStack(spacing: Spacing.sm) {
                    if hasTodayDiary {
                        Text("안녕 \(username).")
                            .font(.titleSmall1)
                            .foregroundColor(.primaryDark)
                        Text("멋진 하루 보내세요!")
                            .font(.titleSmall2)
                            .foregroundColor(.primaryDark)
                            .padding(.top, 4)
                    } else {
                        Text("안녕 \(username)!")
                            .font(.bodyFont)
                            .foregroundColor(.primaryDark)
                        Text("오늘은 어떤 하루를 보냈나요? ✨")
                            .font(.bodyFont)
                            .foregroundColor(.primaryDark)
                            .padding(.top, 4)
                    }
                }
                .padding(Spacing.md)
                .cornerRadius(CornerRadius.md)
                
                Spacer()
                
                // 일기 쓰기 버튼 (조건부 텍스트)
                Button(action: {
                    navigationPath.append("diary-write")
                }) {
                    HStack(spacing: Spacing.sm) {
                        Text(hasTodayDiary ? "일기 쓰기 [오늘 완료]" : "일기 쓰기")
                            .font(.buttonFont)
                            .padding(16)
                        
                        Spacer()
                        Image(systemName: "plus")
                            .font(.buttonFont)
                            .padding(16)
                    }
                    .foregroundColor(.primaryDark)
                    .frame(width: 350, height: 50)
                    .background(hasTodayDiary ? Color.primaryDark.opacity(0.2) : Color.primaryBlue )
                }
                
                // 히스토리 버튼
                Button(action: {
                    navigationPath.append("diary-history")
                }) {
                    HStack(spacing: Spacing.sm) {
                        Text("일기 보기")
                            .font(.buttonFont)
                            .padding(16)
                        Spacer()
                        Image(systemName: "plus")
                            .font(.buttonFont)
                            .padding(16)
                    }
                }
                .font(.buttonFont)
                .foregroundColor(.primaryDark)
                .frame(width: 350, height: 50)
                .background(Color.primaryYellow)
                
                Spacer()
            }
            .padding(Spacing.md)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        navigationPath.append("profile-settings")
                    }) {
                        Circle()
                            .fill(Color.background)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "person.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primaryDark)
                            )
                    }
                }
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "diary-write":
                    DiaryWriteView(
                        navigationPath: $navigationPath
                    )
                case "diary-history":
                    DiaryHistoryView()
                case "profile-settings":
                    ProfileSettingsView() // 이 뷰는 별도로 구현해야 합니다
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
