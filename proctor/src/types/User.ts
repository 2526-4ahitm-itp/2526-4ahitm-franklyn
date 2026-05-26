import type { Theme } from '@/stores/ThemeStore'

export type UserRole = 'STUDENT' | 'TEACHER'

export interface User {
  id: string
  preferredUsername: string
  email: string
  givenName: string | null
  familyName: string | null
  language: string
  theme: Theme
  role: UserRole
}
