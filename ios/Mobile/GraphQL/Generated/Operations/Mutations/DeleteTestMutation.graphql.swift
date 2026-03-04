// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FranklynAPI {
  struct DeleteTestMutation: GraphQLMutation {
    static let operationName: String = "DeleteTest"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DeleteTest($id: BigInteger!) { deleteTest(id: $id) { __typename id } }"#
      ))

    public var id: BigInteger

    public init(id: BigInteger) {
      self.id = id
    }

    @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

    struct Data: FranklynAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("deleteTest", DeleteTest?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeleteTestMutation.Data.self
      ] }

      var deleteTest: DeleteTest? { __data["deleteTest"] }

      /// DeleteTest
      ///
      /// Parent Type: `DeleteTestRow`
      struct DeleteTest: FranklynAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.DeleteTestRow }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", FranklynAPI.BigInteger.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DeleteTestMutation.Data.DeleteTest.self
        ] }

        var id: FranklynAPI.BigInteger { __data["id"] }
      }
    }
  }

}