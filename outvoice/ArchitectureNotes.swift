// App Architecture for Outvoice

/*
 * App Flow:
 * 1. App Launch
 * 2. Check if user has completed onboarding
 * 3. If not, show OnboardingView
 * 4. After onboarding, show AuthView (Sign up/Sign in)
 * 5. After authentication, show TabView with Invoice as main screen
 * 6. Home and Settings tabs are disabled visually (but remain in structure)
 */

/*
 Main State Management:
     1. AppState - Controls overall app flow
     2. OnboardingState - Manages onboarding carousel
     3. AuthState - Handles authentication
     4. PDFStore - Manages PDF files for the authenticated user
*/


// Data Models:
// 1. User - Authentication info and user metadata
// 2. PDFDocument - Metadata about stored PDFs
// 3. OnboardingItem - Content for onboarding slides (already exists)


// Views:
// 1. AppContainerView - Root view that coordinates flow based on AppState
// 2. OnboardingCarouselView - Enhanced version of your current OnboardingView
// 3. AuthView - Sign in/Sign up with Email and Gmail
// 4. TabContainerView - Modified version of your ContentView with disabled tabs
// 5. PDFListView - List of user's PDFs (primary functionality)
// 6. PDFViewerView - For viewing selected PDFs
