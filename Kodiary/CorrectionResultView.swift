import SwiftUI

struct CorrectionResultView: View {
    let originalText: String
    let corrections: [CorrectionItem]
    @Binding var navigationPath: NavigationPath
    
    @State private var expandedItems: Set<Int> = []
    @State private var isSaving = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 원본 일기 표시
                VStack(alignment: .leading, spacing: 10) {
                    Text("작성한 일기")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(originalText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
                
                // 첨삭 완료 헤더
                VStack(spacing: 10) {
                    HStack {
                        Text("🎉")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("첨삭 완료!")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("총 \(corrections.count)개의 수정점을 찾았어요")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // 첨삭 목록
                VStack(spacing: 10) {
                    ForEach(corrections.indices, id: \.self) { index in
                        CorrectionRow(
                            correction: corrections[index],
                            index: index,
                            isExpanded: expandedItems.contains(index)
                        ) {
                            toggleExpansion(for: index)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("첨삭 결과")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("저장") {
                    saveDiary()
                }
                .fontWeight(.semibold)
                .disabled(isSaving)
            }
        }
    }
    
    func toggleExpansion(for index: Int) {
        if expandedItems.contains(index) {
            expandedItems.remove(index)
        } else {
            expandedItems.insert(index)
        }
    }
    
    @EnvironmentObject var dataManager: DataManager

    func saveDiary() {
        isSaving = true
        
        print("일기 저장 시작...")
        
        // DataManager를 통해 실제 저장
        dataManager.saveDiary(text: originalText, corrections: corrections)
        
        // 저장 애니메이션을 위한 딜레이
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("일기 저장 완료!")
            
            // 홈 화면으로 돌아가기
            navigationPath = NavigationPath()
            
            isSaving = false
        }
    }
}

// 나머지 CorrectionRow 코드는 동일...

struct CorrectionRow: View {
    let correction: CorrectionItem
    let index: Int
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더 (항상 보임)
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        // 수정 타입
                        Text(correction.type)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(typeColor.opacity(0.2))
                            .foregroundColor(typeColor)
                            .cornerRadius(8)
                        
                        // 수정 내용 요약
                        Text("\"\(correction.original)\" → \"\(correction.corrected)\"")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    // 펼치기 아이콘
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 상세 내용 (펼쳤을 때만 보임)
            if isExpanded {
                VStack(alignment: .leading, spacing: 15) {
                    Divider()
                    
                    // 원본
                    VStack(alignment: .leading, spacing: 5) {
                        Text("원래 표현")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("\"\(correction.original)\"")
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // 화살표
                    HStack {
                        Spacer()
                        Text("⬇️")
                            .font(.title2)
                        Spacer()
                    }
                    
                    // 수정안
                    VStack(alignment: .leading, spacing: 5) {
                        Text("수정 제안")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("\"\(correction.corrected)\"")
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // 설명
                    VStack(alignment: .leading, spacing: 5) {
                        Text("설명")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text(correction.explanation)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    // 수정 타입별 색상
    var typeColor: Color {
        switch correction.type {
        case "문법":
            return .orange
        case "맞춤법":
            return .red
        case "표현":
            return .purple
        default:
            return .gray
        }
    }
}

