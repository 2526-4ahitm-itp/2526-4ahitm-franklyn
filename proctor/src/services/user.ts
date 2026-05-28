import { computed, type ComputedRef } from 'vue'
import {
  useMutation,
  useQuery,
  useQueryCache,
  type UseMutationReturn,
  type UseQueryReturn,
} from '@pinia/colada'
import { executeMutation, executeQuery, type NormalizedError } from './graphql'
import { useKeycloakStore } from '@/stores/KeycloakStore'
import type { Theme } from '@/stores/ThemeStore'
import type { User } from '@/types/User'

const USER_KEY = ['user'] as const

const USER_QUERY = /* GraphQL */ `
  query CurrentUser {
    user {
      id
      preferredUsername
      email
      givenName
      familyName
      language
      theme
      role
    }
  }
`

const UPDATE_SETTINGS_MUTATION = /* GraphQL */ `
  mutation UpdateSettings($settings: UpdateUserSettingsInput!) {
    updateSettings(settingsInput: $settings) {
      id
      language
      theme
    }
  }
`

export function useCurrentUser(): UseQueryReturn<User, NormalizedError> {
  return useQuery<User, NormalizedError>({
    key: USER_KEY,
    query: async () => {
      const data = await executeQuery<{ user: User }>(USER_QUERY)
      return data.user
    },
  })
}

export interface UpdateSettingsInput {
  language: string
  theme: Theme
}

export function useUpdateSettings(): UseMutationReturn<User, UpdateSettingsInput, NormalizedError> {
  const queryCache = useQueryCache()
  return useMutation<User, UpdateSettingsInput, NormalizedError>({
    mutation: async (input) => {
      const data = await executeMutation<
        { updateSettings: User },
        { settings: UpdateSettingsInput }
      >(UPDATE_SETTINGS_MUTATION, { settings: input })
      return data.updateSettings
    },
    onSettled: () => queryCache.invalidateQueries({ key: USER_KEY }),
  })
}

export interface Roles {
  isAdmin: ComputedRef<boolean>
  isTeacher: ComputedRef<boolean>
}

export function useRoles(): Roles {
  const kc = useKeycloakStore()
  const isAdmin = computed(() => kc.keycloak.realmAccess?.roles.includes('franklyn-admin') ?? false)
  const isTeacher = computed(
    () => kc.keycloak.tokenParsed?.distinguished_name?.includes('OU=Teacher') ?? false,
  )
  return {
    isAdmin,
    isTeacher,
  }
}
