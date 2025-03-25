import SwiftUI

struct AuthHeaderView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var showingSignIn: Bool
    
    var body: some View {
        HStack {
            if authService.isAuthenticated, let user = authService.currentUser {
                Text("Hi, \(user.displayName)")
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            } else {
                Text("Welcome")
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            if authService.isAuthenticated {
                Button(action: {
                    Task {
                        try? await authService.signOut()
                    }
                }) {
                    Text("Sign Out")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            } else {
                Button(action: {
                    showingSignIn = true
                }) {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Create a ViewModifier for consistent styling
struct AuthHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.bottom, 20)
            .padding(.horizontal, 10)
    }
}

// Create a View extension for easy application
extension View {
    func withAuthHeaderStyle() -> some View {
        modifier(AuthHeaderModifier())
    }
} 