package at.ac.htlleonding.franklynserver.websocket;

public enum Profiles {
    HIGH(1920),
    MEDIUM(1280),
    LOW(640);

    private final int maxSidePx;

    Profiles(int maxSidePx) {
        this.maxSidePx = maxSidePx;
    }

    public int getMaxSidePx() {
        return maxSidePx;
    }

    public static Profiles stringify(String profile) {
        try {
            return Profiles.valueOf(profile.toUpperCase());
        } catch (IllegalArgumentException e) {
            return MEDIUM;
        }
    }
}
