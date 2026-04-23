// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension FranklynAPI {
  struct InsertExamInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      endTime: DateTime,
      startTime: DateTime,
      title: String
    ) {
      __data = InputDict([
        "endTime": endTime,
        "startTime": startTime,
        "title": title
      ])
    }

    /// ISO-8601
    var endTime: DateTime {
      get { __data["endTime"] }
      set { __data["endTime"] = newValue }
    }

    /// ISO-8601
    var startTime: DateTime {
      get { __data["startTime"] }
      set { __data["startTime"] = newValue }
    }

    var title: String {
      get { __data["title"] }
      set { __data["title"] = newValue }
    }
  }

}