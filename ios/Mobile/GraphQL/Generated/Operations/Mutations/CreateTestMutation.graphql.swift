// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FranklynAPI {
  struct CreateTestMutation: GraphQLMutation {
    static let operationName: String = "CreateTest"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateTest($test: TestInput) { createTest(test: $test) { __typename id title startTime endTime teacherId pin } }"#
      ))

    public var test: GraphQLNullable<TestInput>

    public init(test: GraphQLNullable<TestInput>) {
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
      /// Parent Type: `Test`
      struct CreateTest: FranklynAPI.SelectionSet {
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
          .field("pin", Int?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CreateTestMutation.Data.CreateTest.self
        ] }

        var id: String? { __data["id"] }
        var title: String? { __data["title"] }
        /// ISO-8601
        var startTime: FranklynAPI.DateTime? { __data["startTime"] }
        /// ISO-8601
        var endTime: FranklynAPI.DateTime? { __data["endTime"] }
        var teacherId: String? { __data["teacherId"] }
        var pin: Int? { __data["pin"] }
      }
    }
  }

}