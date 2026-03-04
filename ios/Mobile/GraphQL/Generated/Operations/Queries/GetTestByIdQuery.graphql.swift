// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FranklynAPI {
  struct GetTestByIdQuery: GraphQLQuery {
    static let operationName: String = "GetTestById"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetTestById($id: BigInteger!) { testId(id: $id) { __typename id title startTime endTime teacherId testAccountPrefix } }"#
      ))

    public var id: BigInteger

    public init(id: BigInteger) {
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
      /// Parent Type: `FindTestByIdRow`
      struct TestId: FranklynAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.FindTestByIdRow }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", FranklynAPI.BigInteger.self),
          .field("title", String?.self),
          .field("startTime", FranklynAPI.DateTime?.self),
          .field("endTime", FranklynAPI.DateTime?.self),
          .field("teacherId", FranklynAPI.BigInteger?.self),
          .field("testAccountPrefix", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetTestByIdQuery.Data.TestId.self
        ] }

        var id: FranklynAPI.BigInteger { __data["id"] }
        var title: String? { __data["title"] }
        /// ISO-8601
        var startTime: FranklynAPI.DateTime? { __data["startTime"] }
        /// ISO-8601
        var endTime: FranklynAPI.DateTime? { __data["endTime"] }
        var teacherId: FranklynAPI.BigInteger? { __data["teacherId"] }
        var testAccountPrefix: String? { __data["testAccountPrefix"] }
      }
    }
  }

}