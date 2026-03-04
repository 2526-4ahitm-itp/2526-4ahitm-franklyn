// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FranklynAPI {
  struct GetTestsQuery: GraphQLQuery {
    static let operationName: String = "GetTests"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetTests { tests { __typename id title startTime endTime teacherId testAccountPrefix } }"#
      ))

    public init() {}

    struct Data: FranklynAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("tests", [Test?]?.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetTestsQuery.Data.self
      ] }

      var tests: [Test?]? { __data["tests"] }

      /// Test
      ///
      /// Parent Type: `FindAllTestsRow`
      struct Test: FranklynAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.FindAllTestsRow }
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
          GetTestsQuery.Data.Test.self
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