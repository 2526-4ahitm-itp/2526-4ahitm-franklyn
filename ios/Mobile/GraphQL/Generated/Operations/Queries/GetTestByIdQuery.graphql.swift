// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FranklynAPI {
  struct GetTestByIdQuery: GraphQLQuery {
    static let operationName: String = "GetTestById"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetTestById($id: String) { testId(id: $id) { __typename id title startTime endTime teacherId } }"#
      ))

    public var id: GraphQLNullable<String>

    public init(id: GraphQLNullable<String>) {
      self.id = id
    }

    @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

    struct Data: FranklynAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("testId", TestId?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetTestByIdQuery.Data.self
      ] }

      var testId: TestId? { __data["testId"] }

      /// TestId
      ///
      /// Parent Type: `Test`
      struct TestId: FranklynAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.Test }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String?.self),
          .field("title", String?.self),
          .field("startTime", FranklynAPI.DateTime?.self),
          .field("endTime", FranklynAPI.DateTime?.self),
          .field("teacherId", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetTestByIdQuery.Data.TestId.self
        ] }

        var id: String? { __data["id"] }
        var title: String? { __data["title"] }
        /// ISO-8601
        var startTime: FranklynAPI.DateTime? { __data["startTime"] }
        /// ISO-8601
        var endTime: FranklynAPI.DateTime? { __data["endTime"] }
        var teacherId: String? { __data["teacherId"] }
      }
    }
  }

}