package at.ac.htlleonding.franklynserver;

import java.util.UUID;

public record Frame (UUID sentinelId, UUID frameId, int index, String data) {
}
