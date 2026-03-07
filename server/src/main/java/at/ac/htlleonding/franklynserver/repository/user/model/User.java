package at.ac.htlleonding.franklynserver.repository.user.model;

import java.util.UUID;

import io.smallrye.common.constraint.NotNull;
import io.smallrye.common.constraint.Nullable;

public abstract class User {
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

    public User() {
    }

    public User(@NotNull UUID id,
            @NotNull String preferredUsername,
            @NotNull String email,
            @Nullable String givenName,
            @Nullable String familyName) {
        this.id = id;
        this.preferredUsername = preferredUsername;
        this.email = email;
        this.givenName = givenName;
        this.familyName = familyName;
    }

}
