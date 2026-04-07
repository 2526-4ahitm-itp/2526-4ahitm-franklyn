import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var loginService: LoginService
    @State private var selectedTab = 0
    @State private var versionService = VersionService.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            testsTab
                .tabItem {
                    Label("Tests", systemImage: "doc.text")
                }
                .tag(0)
            
            screensTab
                .tabItem {
                    Label("Screens", systemImage: "rectangle.on.rectangle")
                }
                .tag(1)
            
            profileTab
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
        .task {
            await versionService.fetchVersion()
        }
    }
    
    private var testsTab: some View {
        NavigationStack {
            ZStack {
                TestListView(onProfileTapped: { selectedTab = 2 })
                    .navigationDestination(for: String.self) { testId in
                        TestDetailView(testId: testId)
                    }
            }
            .navigationTitle("Tests")
        }
    }
    
    private var screensTab: some View {
        NavigationStack {
            ScreenView()
                .navigationTitle("Screens")
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
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Not Logged In")
                .font(.title2.weight(.semibold))
            
            Text("Sign in to access your profile and manage your tests.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            loginButton
            
            Spacer()
        }
        .navigationTitle("Profile")
    }
    
    private var loginButton: some View {
        Button(action: {
            loginService.discoverConfiguration(test: "")
        }) {
            HStack {
                Image(systemName: "person.crop.circle.badge.plus")
                Text("Login with Keycloak")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(10)
        }
    }
}

#Preview {
    ContentView()
        .environment(TestStore())
        .environmentObject(LoginService.shared)
}
