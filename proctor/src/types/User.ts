import type { Theme } from '@/stores/ThemeStore'

export type UserRole = 'STUDENT' | 'TEACHER'

export interface UserSettings {
  userId?: string
  theme: Theme
  language: string
}

export interface User {
  id: string
  preferredUsername: string
  email: string
  givenName: string | null
  familyName: string | null
  role: UserRole
  settings?: UserSettings
}
