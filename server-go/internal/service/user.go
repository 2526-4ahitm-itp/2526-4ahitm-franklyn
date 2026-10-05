// The service package encapsulates logic between the representation and the
// data layer.
// Users are hidden behind the service functions so complete user operations can
// be guarenteed. In this service, the composition of user and teacher/student
// are safely encapsulated. The entire application should only interact with
// presistent users through this service.
package service
