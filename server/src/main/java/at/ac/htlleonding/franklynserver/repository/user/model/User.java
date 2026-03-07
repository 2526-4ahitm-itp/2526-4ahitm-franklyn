package at.ac.htlleonding.franklynserver.repository.user.model;

import java.util.UUID;

import io.smallrye.common.constraint.NotNull;
import io.smallrye.common.constraint.Nullable;

public class User {
    @NotNull
    public UUID id;

    @NotNull
    public String preferredUsername;

    @NotNull
    public String email;

    @Nullable
    public String givenName;

    @Nullable
    public String familyName;
}
