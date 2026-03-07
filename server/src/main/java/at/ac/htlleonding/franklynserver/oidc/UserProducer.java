package at.ac.htlleonding.franklynserver.oidc;

import io.quarkus.security.ForbiddenException;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.enterprise.context.RequestScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Inject;

import at.ac.htlleonding.franklynserver.repository.user.model.Student;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.user.model.User;

@RequestScoped
public class UserProducer {

    @Inject
    SecurityIdentity identity;

    @Inject
    OidcUserService oidcUserService;

    private User resolvedUser;

    private User getOrResolve() {
        if (resolvedUser == null) {
            resolvedUser = oidcUserService.resolveUser(identity);
        }
        return resolvedUser;
    }

    @Produces
    @RequestScoped
    User produceUser() {
        return getOrResolve();
    }

    @Produces
    @RequestScoped
    Teacher produceTeacher() {
        var user = getOrResolve();
        if (user instanceof Teacher teacher) {
            return teacher;
        }
        throw new ForbiddenException("Not a teacher");
    }

    @Produces
    @RequestScoped
    Student produceStudent() {
        var user = getOrResolve();
        if (user instanceof Student student) {
            return student;
        }
        throw new ForbiddenException("Not a student");
    }
}
