import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var loginService: LoginService
    @State private var selectedTab = 0
    @State private var versionService = VersionService.shared
    
    var body: some View {
        Group {
            if loginService.isLoggedIn {
                TabView(selection: $selectedTab) {
                    examsTab
                        .tabItem {
                            Label("Exams", systemImage: "doc.text")
                        }
                        .tag(0)
                    
                    screensTab
                        .tabItem {
                            Label("Detailed View", systemImage: "rectangle")
                        }
                        .tag(1)
                    
                    profileTab
                        .tabItem {
                            Label("Profile", systemImage: "person.circle")
                        }
                        .tag(2)
                    tableTab
                        .tabItem {
                            Label("Overview", systemImage: "rectangle.on.rectangle")
                        }
                }
                .task {
                    await versionService.fetchVersion()
                }
            } else {
                LoginLandingView()
            }
        }
        .onChange(of: loginService.isLoggedIn) { _, isLoggedIn in
            if !isLoggedIn {
                WebsocketStore.shared.disconnect()
            }
        }
    }
    
    private var examsTab: some View {
        NavigationStack {
            ZStack {
                ExamListView(onProfileTapped: { selectedTab = 2 })
                    .navigationDestination(for: String.self) { examId in
                        ExamDetailView(examId: examId)
                    }
            }
            .navigationTitle("Exams")
        }
    }
    
    private var screensTab: some View {
        NavigationStack {
            ScreenView()
                .navigationTitle("Detailed View")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            selectedTab = 2
                        } label: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
        }
    }
    
    private var profileTab: some View {
        NavigationStack {
            if loginService.isLoggedIn {
                loggedInProfile
            } else {
                loggedOutProfile
            }
        }
    }
    private var tableTab : some View {
        NavigationStack {
            TableView()
                .navigationTitle("Overview")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            selectedTab = 2
                        } label: {
                            Image(systemName: "rectangle.on.rectangle")
                                .foregroundColor(.blue)
                        }
                    }
                }
        }
    }
    
    private var loggedInProfile: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loginService.userName ?? "User")
                            .font(.title2.weight(.semibold))
                        if let email = loginService.userEmail {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Account") {
                LabeledContent("Username", value: loginService.userName ?? "N/A")
                LabeledContent("Email", value: loginService.userEmail ?? "N/A")
                LabeledContent("Status", value: "Active")
                    .foregroundColor(.green)
            }
            
            Section("Settings") {
                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    Label("Appearance", systemImage: "paintbrush")
                }
            }
            
            Section("App Info") {
                LabeledContent("Version", value: versionService.version)
                LabeledContent("Build", value: versionService.build)
            }
            
            Section {
                Button(role: .destructive) {
                    loginService.logout()
                } label: {
                    HStack {
                        Spacer()
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Profile")
    }
    
    private var loggedOutProfile: some View {
        LoginLandingView()
    }
}

#Preview {
    ContentView()
        .environment(ExamStore())
        .environmentObject(LoginService.shared)
}
