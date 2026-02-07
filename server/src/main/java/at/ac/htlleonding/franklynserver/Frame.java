package at.ac.htlleonding.franklynserver;

import java.util.UUID;

public class Frame {
    public UUID sentinelId;

    public UUID frameId;

    public int index;

    public String data;

    public Frame() {
    }

    public Frame(UUID sentinelId, UUID frameId, int index, String data) {
        this.sentinelId = sentinelId;
        this.frameId = frameId;
        this.index = index;
        this.data = data;
    }
}
