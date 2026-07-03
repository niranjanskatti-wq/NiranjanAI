// Authentication Architecture for Niranjan AI Workspace
// Prepared for Future Integration (NextAuth.js / Firebase / Clerk)

export type UserRole = "owner" | "admin" | "member" | "guest";

export interface UserProfile {
  id: string;
  name: string;
  email: string;
  avatarUrl?: string;
  role: UserRole;
  createdAt: string;
}

export interface AuthSession {
  user: UserProfile | null;
  accessToken: string | null;
  isAuthenticated: boolean;
  loginMethod: "guest" | "google" | "github" | "email" | null;
}

// Service helper to manage auth mapping and callback flows
export class AuthService {
  // Mock login provider triggers
  static async loginWithGoogle(): Promise<AuthSession> {
    console.log("Redirecting callback flow to Google OAuth endpoint...");
    return this.createMockSession("Google User", "google@ai-os.com", "google");
  }

  static async loginWithGitHub(): Promise<AuthSession> {
    console.log("Redirecting callback flow to GitHub OAuth endpoint...");
    return this.createMockSession("GitHub Dev", "github@ai-os.com", "github");
  }

  static async loginWithEmail(email: string): Promise<AuthSession> {
    console.log(`Sending Magic OTP link connection to ${email}...`);
    return this.createMockSession("Email User", email, "email");
  }

  static async loginAsGuest(): Promise<AuthSession> {
    console.log("Initializing local Sandboxed Guest profile session...");
    return this.createMockSession("Sandbox Guest", "guest@ai-os.com", "guest");
  }

  private static createMockSession(
    name: string,
    email: string,
    method: AuthSession["loginMethod"]
  ): AuthSession {
    return {
      user: {
        id: `usr-${Math.random().toString(36).substr(2, 9)}`,
        name,
        email,
        role: method === "guest" ? "guest" : "owner",
        createdAt: new Date().toISOString()
      },
      accessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      isAuthenticated: true,
      loginMethod: method
    };
  }
}
