// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FranklynAPI {
  struct CreateExamMutation: GraphQLMutation {
    static let operationName: String = "CreateExam"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateExam($exam: InsertExamInput!) { createExam(examInput: $exam) { __typename id title startTime endTime startedAt endedAt teacherId pin } }"#
      ))

    public var exam: InsertExamInput

    public init(exam: InsertExamInput) {
      self.exam = exam
    }

    @_spi(Unsafe) public var __variables: Variables? { ["exam": exam] }

    struct Data: FranklynAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createExam", CreateExam.self, arguments: ["examInput": .variable("exam")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateExamMutation.Data.self
      ] }

      var createExam: CreateExam { __data["createExam"] }

      /// CreateExam
      ///
      /// Parent Type: `Exam`
      struct CreateExam: FranklynAPI.SelectionSet {
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
          CreateExamMutation.Data.CreateExam.self
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