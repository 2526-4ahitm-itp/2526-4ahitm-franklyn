// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FranklynAPI {
  struct UpdateTestMutation: GraphQLMutation {
    static let operationName: String = "UpdateTest"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdateTest($id: BigInteger!, $test: UpdateTestRowInput) { updateTest(id: $id, test: $test) { __typename id title startTime endTime teacherId testAccountPrefix } }"#
      ))

    public var id: BigInteger
    public var test: GraphQLNullable<UpdateTestRowInput>

    public init(
      id: BigInteger,
      test: GraphQLNullable<UpdateTestRowInput>
    ) {
      self.id = id
      self.test = test
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "id": id,
      "test": test
    ] }

    struct Data: FranklynAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("updateTest", UpdateTest?.self, arguments: [
          "id": .variable("id"),
          "test": .variable("test")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdateTestMutation.Data.self
      ] }

      var updateTest: UpdateTest? { __data["updateTest"] }

      /// UpdateTest
      ///
      /// Parent Type: `UpdateTestRow`
      struct UpdateTest: FranklynAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.UpdateTestRow }
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
          UpdateTestMutation.Data.UpdateTest.self
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