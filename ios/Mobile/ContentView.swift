import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var loginService: LoginService
    
    var body: some View {
        NavigationStack {
            ZStack {
                TestListView()
                    .navigationDestination(for: String.self) { testId in
                        TestDetailView(testId: testId)
                    }
                
                VStack {
                    Spacer()
                    if loginService.isLoggedIn {
                        loggedInView
                    } else {
                        loginButton
                    }
                }
                .padding()
            }
            NavigationLink(destination: ScreenView()) {
                Text("Screens")
            }
        }
    }
    
    private var loggedInView: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(loginService.userName ?? "Logged in")
                    .font(.headline)
                if let email = loginService.userEmail {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                loginService.logout()
            }) {
                Text("Logout")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
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