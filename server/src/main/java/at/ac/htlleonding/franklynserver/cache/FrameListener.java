package at.ac.htlleonding.franklynserver.cache;

import at.ac.htlleonding.franklynserver.Frame;

import java.util.UUID;
import java.util.function.Consumer;

public class FrameListener {
    public UUID sentinelId;

    public Consumer<Frame> frameConsumer = frame -> {

    };

    public FrameListener(UUID sentinelId, Consumer<Frame> frameConsumer) {
        this.sentinelId = sentinelId;
        this.frameConsumer = frameConsumer;
    }

    public FrameListener() {
    }
}
