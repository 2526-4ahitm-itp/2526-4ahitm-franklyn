import { ApolloClient, HttpLink, InMemoryCache } from '@apollo/client'
import { SetContextLink } from '@apollo/client/link/context'
import { defineStore } from 'pinia'
import { useKeycloakStore } from './KeycloakStore'

export const useApolloClientStore = defineStore('apolloClientStore', () => {
  const { keycloak } = useKeycloakStore()

  const httpLink = new HttpLink({
    uri: '/api/graphql',
  })

  const authLink = new SetContextLink((prevContext) => ({
    headers: {
      ...prevContext.headers,
      Authorization: `Bearer ${keycloak.token}`,
    },
  }))

  const client = new ApolloClient({
    link: authLink.concat(httpLink),
    cache: new InMemoryCache(),
  })

  return {
    client,
  }
})
