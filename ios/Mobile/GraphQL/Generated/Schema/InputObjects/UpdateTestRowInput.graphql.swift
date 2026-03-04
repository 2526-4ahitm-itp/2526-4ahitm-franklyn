// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension FranklynAPI {
  struct UpdateTestRowInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      endTime: GraphQLNullable<DateTime> = nil,
      id: BigInteger,
      startTime: GraphQLNullable<DateTime> = nil,
      teacherId: GraphQLNullable<BigInteger> = nil,
      testAccountPrefix: GraphQLNullable<String> = nil,
      title: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "endTime": endTime,
        "id": id,
        "startTime": startTime,
        "teacherId": teacherId,
        "testAccountPrefix": testAccountPrefix,
        "title": title
      ])
    }

    /// ISO-8601
    var endTime: GraphQLNullable<DateTime> {
      get { __data["endTime"] }
      set { __data["endTime"] = newValue }
    }

    var id: BigInteger {
      get { __data["id"] }
      set { __data["id"] = newValue }
    }

    /// ISO-8601
    var startTime: GraphQLNullable<DateTime> {
      get { __data["startTime"] }
      set { __data["startTime"] = newValue }
    }

    var teacherId: GraphQLNullable<BigInteger> {
      get { __data["teacherId"] }
      set { __data["teacherId"] = newValue }
    }

    var testAccountPrefix: GraphQLNullable<String> {
      get { __data["testAccountPrefix"] }
      set { __data["testAccountPrefix"] = newValue }
    }

    var title: GraphQLNullable<String> {
      get { __data["title"] }
      set { __data["title"] = newValue }
    }
  }

}