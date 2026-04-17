import { ApolloClient, HttpLink, InMemoryCache } from '@apollo/client'
import { SetContextLink } from '@apollo/client/link/context'
import { defineStore } from 'pinia'
import { useKeycloakStore } from './KeycloakStore'

export const useApolloClientStore = defineStore('apolloClientStore', () => {
  const { keycloak } = useKeycloakStore()

  const httpLink = new HttpLink({
    uri: '/api/graphql',
  })

  const authLink = new SetContextLink(async (prevContext) => {
    try {
      await keycloak.updateToken(30)
    } catch (e) {
      console.error(e)
      await keycloak.login()
    }

    return {
      headers: {
        ...prevContext.headers,
        Authorization: `Bearer ${keycloak.token}`,
      },
    }
  })

  const dateField = { read: (v: string | null) => (v ? new Date(v) : v) }

  const client = new ApolloClient({
    link: authLink.concat(httpLink),
    cache: new InMemoryCache({
      typePolicies: {
        Exam: {
          fields: {
            startTime: dateField,
            endTime: dateField,
            startedAt: dateField,
            endedAt: dateField,
          },
        },
        Notice: {
          fields: {
            endTime: dateField,
            startTime: dateField,
          },
        },
      },
    }),
  })

  return {
    client,
  }
})
