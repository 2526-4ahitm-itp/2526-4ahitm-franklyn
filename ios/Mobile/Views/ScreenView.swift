//
//  ScreenView.swift
//  Mobile
//
//  Created by geldin on 08.04.26.
//

import SwiftUI
import UIKit

struct SentinelIdWrapper: Identifiable {
    let id: String
}

struct ScreenView: View {
    @State private var store = WebsocketStore.shared
    @State private var examStore = ExamStore()
    @State private var selectedExam: FrExam?
    @State private var selectedSentinel: SentinelIdWrapper?

    var body: some View {
        VStack(spacing: 0) {
            examSelector
            sentinelGrid
        }
        .task {
            await examStore.fetchExams()
        }
        .onAppear {
            store.connectWebsocket()
        }
        .fullScreenCover(item: $selectedSentinel) { sentinel in
            LandscapeFullscreenView(
                sentinelId: sentinel.id,
                name: store.sentinelName(for: sentinel.id) ?? sentinel.id,
                image: store.framesBySentinel[sentinel.id],
                onDismiss: { selectedSentinel = nil }
            )
        }
    }
    
    private var examSelector: some View {
        VStack(alignment: .leading) {
            Text("Select Exam")
                .font(.headline)
            
            if examStore.liveExams.isEmpty {
                Text("No live exams")
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(examStore.liveExams) { exam in
                            ExamChip(
                                exam: exam,
                                isSelected: selectedExam?.id == exam.id,
                                onTap: {
                                    selectExam(exam)
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(8)
        .frame(height: 80)

    }
    
    private func selectExam(_ exam: FrExam) {
        if selectedExam?.id == exam.id {
            selectedExam = nil
            store.clearPinFilter()
        } else {
            selectedExam = exam
            if let pin = exam.pin {
                store.setPinFilter(pin: pin)
            }
        }
    }
    
    private var sentinelGrid: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(store.framesBySentinel.keys.sorted(), id: \.self) { sentinelId in
                    Button {
                        selectedSentinel = SentinelIdWrapper(id: sentinelId)
                    } label: {
                        VStack {
                            Text(store.sentinelName(for: sentinelId) ?? sentinelId)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            if let image = store.framesBySentinel[sentinelId] {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 400)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

struct LandscapeFullscreenView: View {
    let sentinelId: String
    let name: String
    let image: UIImage?
    let onDismiss: () -> Void
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if verticalSizeClass == .compact {
                landscapeView
            } else {
                portraitView
            }
        }
        .statusBar(hidden: true)
    }
    
    private var portraitView: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Close") {
                    onDismiss()
                }
                .foregroundColor(.white)
                .padding()
                
                Spacer()
                
                Text(name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.top, 40)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
    }
    
    private var landscapeView: some View {
        let scaleFactor = 0.93
        
        return VStack(spacing: 0) {
            HStack {
                Button("Close") {
                    onDismiss()
                }
                .foregroundColor(.white)
                .padding()
                
                Spacer()
                
                Text(name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.top, 40)
            .scaleEffect(scaleFactor)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        maxWidth: UIScreen.main.bounds.width * scaleFactor,
                        maxHeight: UIScreen.main.bounds.height * scaleFactor
                    )
                    .clipped()
            }
        }
    }
}

struct ExamChip: View {
    let exam: FrExam
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exam.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let pin = exam.pin {
                    Text("PIN: \(pin)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.white)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
