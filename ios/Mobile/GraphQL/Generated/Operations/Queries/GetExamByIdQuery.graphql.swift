// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FranklynAPI {
  struct GetExamByIdQuery: GraphQLQuery {
    static let operationName: String = "GetExamById"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetExamById($id: String!) { examById: examId(id: $id) { __typename id title startTime endTime startedAt endedAt teacherId pin } }"#
      ))

    public var id: String

    public init(id: String) {
      self.id = id
    }

    @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

    struct Data: FranklynAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("examId", alias: "examById", ExamById?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetExamByIdQuery.Data.self
      ] }

      var examById: ExamById? { __data["examById"] }

      /// ExamById
      ///
      /// Parent Type: `Exam`
      struct ExamById: FranklynAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.Exam }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String?.self),
          .field("title", String.self),
          .field("startTime", FranklynAPI.DateTime.self),
          .field("endTime", FranklynAPI.DateTime.self),
          .field("startedAt", FranklynAPI.DateTime?.self),
          .field("endedAt", FranklynAPI.DateTime?.self),
          .field("teacherId", String.self),
          .field("pin", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetExamByIdQuery.Data.ExamById.self
        ] }

        var id: String? { __data["id"] }
        var title: String { __data["title"] }
        /// ISO-8601
        var startTime: FranklynAPI.DateTime { __data["startTime"] }
        /// ISO-8601
        var endTime: FranklynAPI.DateTime { __data["endTime"] }
        /// ISO-8601
        var startedAt: FranklynAPI.DateTime? { __data["startedAt"] }
        /// ISO-8601
        var endedAt: FranklynAPI.DateTime? { __data["endedAt"] }
        var teacherId: String { __data["teacherId"] }
        var pin: Int { __data["pin"] }
      }
    }
  }

}