// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FranklynAPI {
  struct UpdateExamScheduleMutation: GraphQLMutation {
    static let operationName: String = "UpdateExamSchedule"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdateExamSchedule($id: String!, $schedule: UpdateExamScheduleInput!) { updateExamSchedule(examId: $id, examScheduleInput: $schedule) { __typename id title startTime endTime startedAt endedAt teacherId pin } }"#
      ))

    public var id: String
    public var schedule: UpdateExamScheduleInput

    public init(
      id: String,
      schedule: UpdateExamScheduleInput
    ) {
      self.id = id
      self.schedule = schedule
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "id": id,
      "schedule": schedule
    ] }

    struct Data: FranklynAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FranklynAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("updateExamSchedule", UpdateExamSchedule.self, arguments: [
          "examId": .variable("id"),
          "examScheduleInput": .variable("schedule")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdateExamScheduleMutation.Data.self
      ] }

      var updateExamSchedule: UpdateExamSchedule { __data["updateExamSchedule"] }

      /// UpdateExamSchedule
      ///
      /// Parent Type: `Exam`
      struct UpdateExamSchedule: FranklynAPI.SelectionSet {
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
          UpdateExamScheduleMutation.Data.UpdateExamSchedule.self
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