// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

protocol FranklynAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == FranklynAPI.SchemaMetadata {}

protocol FranklynAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == FranklynAPI.SchemaMetadata {}

protocol FranklynAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == FranklynAPI.SchemaMetadata {}

protocol FranklynAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == FranklynAPI.SchemaMetadata {}

extension FranklynAPI {
  typealias SelectionSet = FranklynAPI_SelectionSet

  typealias InlineFragment = FranklynAPI_InlineFragment

  typealias MutableSelectionSet = FranklynAPI_MutableSelectionSet

  typealias MutableInlineFragment = FranklynAPI_MutableInlineFragment

  enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      switch typename {
      case "DeleteTestRow": return FranklynAPI.Objects.DeleteTestRow
      case "FindAllTestsRow": return FranklynAPI.Objects.FindAllTestsRow
      case "FindTestByIdRow": return FranklynAPI.Objects.FindTestByIdRow
      case "InsertTestRow": return FranklynAPI.Objects.InsertTestRow
      case "Mutation": return FranklynAPI.Objects.Mutation
      case "Query": return FranklynAPI.Objects.Query
      case "UpdateTestRow": return FranklynAPI.Objects.UpdateTestRow
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}