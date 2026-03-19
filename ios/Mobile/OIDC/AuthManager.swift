//
//  AuthManager.swift
//  Mobile
//
//  Created by Clemens Zangenfeind on 17.03.26.
//

import Foundation
import Apollo
import ApolloAPI

/// Custom interceptor that adds the Authorization header with the access token.
class AuthorizationInterceptor: ApolloInterceptor {
    var id: String = "AuthorizationInterceptor"
    
    func interceptAsync<Operation: GraphQLOperation>(
        chain: any RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, any Error>) -> Void
    ) {
        // Try to get the access token and add it to the request
        if let token = TokenStorage.shared.accessToken {
            request.addHeader(name: "Authorization", value: "Bearer \(token)")
            print("[AuthInterceptor] Added authorization header")
        } else {
            print("[AuthInterceptor] No access token available")
        }
        
        // Continue the chain
        chain.proceedAsync(
            request: request,
            response: response,
            interceptor: self,
            completion: completion
        )
    }
}

/// Custom interceptor provider that includes our authorization interceptor.
class AuthInterceptorProvider: DefaultInterceptorProvider {
    override func interceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [any ApolloInterceptor] {
        var interceptors = super.interceptors(for: operation)
        // Insert our auth interceptor at the beginning
        interceptors.insert(AuthorizationInterceptor(), at: 0)
        return interceptors
    }
}

/// Creates and manages the authenticated Apollo client.
class ApolloClientManager {
    static let shared = ApolloClientManager()
    
    private(set) var client: ApolloClient
    
    private init() {
        let url = URL(string: "http://localhost:5050/api/graphql")!
        let store = ApolloStore()
        let interceptorProvider = AuthInterceptorProvider(store: store)
        let networkTransport = RequestChainNetworkTransport(
            interceptorProvider: interceptorProvider,
            endpointURL: url
        )
        
        self.client = ApolloClient(networkTransport: networkTransport, store: store)
        print("[ApolloClientManager] Initialized with auth interceptor")
    }
    
    /// Reinitialize the client (e.g., after logout/login).
    func reinitialize() {
        let url = URL(string: "http://localhost:5050/api/graphql")!
        let store = ApolloStore()
        let interceptorProvider = AuthInterceptorProvider(store: store)
        let networkTransport = RequestChainNetworkTransport(
            interceptorProvider: interceptorProvider,
            endpointURL: url
        )
        
        self.client = ApolloClient(networkTransport: networkTransport, store: store)
        print("[ApolloClientManager] Reinitialized")
    }
}
