package at.ac.htlleonding.franklynserver.repository.user.model;

public enum UserTheme {
    DARK("dark"),
    LIGHT("light"),
    SYSTEM("system");

    final String name;

    UserTheme(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }
}
