// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FranklynAPI {
  struct DeleteTestMutation: GraphQLMutation {
    static let operationName: String = "DeleteTest"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DeleteTest($id: String!) { deleteTest: deleteExam(id: $id) }"#
      ))

    public var id: String

    public init(id: String) {
      self.id = id
    }

    @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

    struct Data: FranklynAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("deleteExam", alias: "deleteTest", FranklynAPI.Void?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeleteTestMutation.Data.self
      ] }

      var deleteTest: FranklynAPI.Void? { __data["deleteTest"] }
    }
  }

}