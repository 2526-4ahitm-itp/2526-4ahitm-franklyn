// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FranklynAPI {
  struct CreateTestMutation: GraphQLMutation {
    static let operationName: String = "CreateTest"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateTest($test: InsertTestRowInput) { createTest(test: $test) { __typename id title startTime endTime teacherId testAccountPrefix } }"#
      ))

    public var test: GraphQLNullable<InsertTestRowInput>

    public init(test: GraphQLNullable<InsertTestRowInput>) {
      self.test = test
    }

    @_spi(Unsafe) public var __variables: Variables? { ["test": test] }

    struct Data: FranklynAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createTest", CreateTest?.self, arguments: ["test": .variable("test")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateTestMutation.Data.self
      ] }

      var createTest: CreateTest? { __data["createTest"] }

      /// CreateTest
      ///
      /// Parent Type: `InsertTestRow`
      struct CreateTest: FranklynAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.InsertTestRow }
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
          CreateTestMutation.Data.CreateTest.self
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