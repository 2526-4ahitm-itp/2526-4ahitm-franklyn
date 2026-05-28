import {
  CombinedError,
  createClient,
  definePlugin,
  fetch as villusFetch,
  setActiveClient,
  type Client,
  type ClientPlugin,
} from 'villus'
import type { App } from 'vue'
import { useKeycloakStore } from '@/stores/KeycloakStore'

export type ErrorCode = 'UNAUTHORIZED' | 'FORBIDDEN' | 'NETWORK_ERROR' | 'GRAPHQL_ERROR' | 'UNKNOWN'

export interface NormalizedError {
  code: ErrorCode
  message: string
  raw?: unknown
}

let activeClient: Client | null = null

export function installVillus(app: App): Client {
  const client = createClient({
    url: '/api/graphql',
    use: [authPlugin, villusFetch()],
  })
  setActiveClient(client)
  activeClient = client
  app.provide('villusClient', client)
  return client
}

function getClient(): Client {
  if (!activeClient) {
    throw new Error('GraphQL client is not initialised. Call installVillus(app) first.')
  }
  return activeClient
}

const authPlugin: ClientPlugin = definePlugin(async ({ opContext }) => {
  const kc = useKeycloakStore()
  try {
    await kc.keycloak.updateToken(30)
  } catch {
    await kc.keycloak.login()
  }
  const token = kc.keycloak.token
  if (token) {
    opContext.headers = {
      ...opContext.headers,
      Authorization: `Bearer ${token}`,
    }
  }
})

export async function executeQuery<
  TData,
  TVars extends Record<string, unknown> = Record<string, never>,
>(query: string, variables?: TVars): Promise<TData> {
  const { data, error } = await getClient().executeQuery<TData, TVars>({
    query,
    variables: variables ?? ({} as TVars),
    cachePolicy: 'network-only',
  })
  if (error) throw normalizeGqlError(error)
  if (data === null) throw normalizeGqlError(new Error('No data returned'))
  return data
}

export async function executeMutation<
  TData,
  TVars extends Record<string, unknown> = Record<string, never>,
>(query: string, variables?: TVars): Promise<TData> {
  const { data, error } = await getClient().executeMutation<TData, TVars>({
    query,
    variables: variables ?? ({} as TVars),
  })
  if (error) throw normalizeGqlError(error)
  if (data === null) throw normalizeGqlError(new Error('No data returned'))
  return data
}

export function normalizeGqlError(err: unknown): NormalizedError {
  if (err instanceof CombinedError) {
    const graphqlError = err.graphqlErrors?.[0]
    if (graphqlError) {
      const extensions = (graphqlError as { extensions?: Record<string, unknown> }).extensions
      const code = typeof extensions?.code === 'string' ? extensions.code : ''
      if (code === 'UNAUTHORIZED' || code === 'FORBIDDEN') {
        return { code, message: graphqlError.message, raw: err }
      }
      return { code: 'GRAPHQL_ERROR', message: graphqlError.message, raw: err }
    }
    if (err.networkError) {
      const response = (err as { response?: { status?: number } }).response
      const status = response?.status
      if (status === 401)
        return { code: 'UNAUTHORIZED', message: err.networkError.message, raw: err }
      if (status === 403) return { code: 'FORBIDDEN', message: err.networkError.message, raw: err }
      return { code: 'NETWORK_ERROR', message: err.networkError.message, raw: err }
    }
  }
  if (err instanceof Error) {
    return { code: 'UNKNOWN', message: err.message, raw: err }
  }
  return { code: 'UNKNOWN', message: 'Unknown error', raw: err }
}

export function isNormalizedError(err: unknown): err is NormalizedError {
  return (
    typeof err === 'object' &&
    err !== null &&
    'code' in err &&
    'message' in err &&
    typeof (err as NormalizedError).code === 'string'
  )
}
