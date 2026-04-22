//
//  TableView.swift
//  Mobile
//
//  Created by Clemens Zangenfeind on 22.04.26.
//
import SwiftUI
import UIKit
 
struct TableView: View {
    @State private var store = WebsocketStore()
    @State private var testStore = TestStore()
    @State private var selectedTest: FrTest?
    @State private var selectedSentinel: SentinelIdWrapper?
 
    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
 
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
        .background(Color.secondary.opacity(0.1))
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
        let sentinelIds = store.framesBySentinel.keys.sorted()
 
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Sentinel count header
                HStack(spacing: 6) {
                    Text("\(sentinelIds.count)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(minWidth: 28, minHeight: 20)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .clipShape(Capsule())
 
                    Text(sentinelIds.count == 1 ? "Sentinel" : "Sentinels")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 4)
 
                if sentinelIds.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No sentinels connected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(sentinelIds, id: \.self) { sentinelId in
                            Button {
                                selectedSentinel = SentinelIdWrapper(id: sentinelId)
                            } label: {
                                SentinelCard(
                                    name: store.sentinelName(for: sentinelId) ?? sentinelId,
                                    image: store.framesBySentinel[sentinelId]
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}
 
// MARK: - Sentinel Card
 
struct SentinelCard: View {
    let name: String
    let image: UIImage?
 
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Color.black.opacity(0.05)
 
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                } else {
                    Image(systemName: "video.slash")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
 
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
