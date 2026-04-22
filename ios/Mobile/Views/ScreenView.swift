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
    @State private var store = WebsocketStore()
    @State private var testStore = TestStore()
    @State private var selectedTest: FrTest?
    @State private var selectedSentinel: SentinelIdWrapper?

    var body: some View {
        VStack(spacing: 0) {
            testSelector
            sentinelGrid
        }
        .task {
            await testStore.fetchTests()
        }
        .onAppear {
            store.connectWebsocket()
        }
        .onDisappear {
            store.disconnect()
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
    
    private var testSelector: some View {
        VStack(alignment: .leading) {
            Text("Select Test")
                .font(.headline)
            
            if testStore.activeTests.isEmpty {
                Text("No active tests")
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(testStore.activeTests) { test in
                            TestChip(
                                test: test,
                                isSelected: selectedTest?.id == test.id,
                                onTap: {
                                    selectTest(test)
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
    
    private func selectTest(_ test: FrTest) {
        if selectedTest?.id == test.id {
            selectedTest = nil
            store.clearPinFilter()
        } else {
            selectedTest = test
            if let pin = test.pin {
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

struct TestChip: View {
    let test: FrTest
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(test.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let pin = test.pin {
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
