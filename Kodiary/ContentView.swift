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
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 30) {
                // 앱 로고 영역
                VStack(spacing: 10) {
                    Text("✍️ Kodiary")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("한국어 일기 첨삭")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // 통계 카드 - 실제 데이터 사용
                if dataManager.getTotalDiariesCount() > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("지금까지")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(dataManager.getTotalDiariesCount())개 일기")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("작성했어요! 🎉")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("📝")
                            .font(.largeTitle)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                // 일기 쓰기 버튼
                Button(action: {
                    navigationPath.append("diary-write")
                }) {
                    HStack {
                        Text("일기 쓰기")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Image(systemName: "pencil")
                    }
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // 히스토리 버튼
                Button("일기 히스토리") {
                    navigationPath.append("diary-history")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                
                Spacer()
            }
            .padding()
            .navigationTitle("홈")
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

