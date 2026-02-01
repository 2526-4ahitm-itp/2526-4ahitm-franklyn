package at.ac.htlleonding.franklynserver.cache;

import java.util.UUID;
import java.util.function.Consumer;

public class FrameListener {
    public UUID sentinelId;

    public Consumer<String> frameConsumer = frame -> {

    };

    public FrameListener(UUID sentinelId, Consumer<String> frameConsumer) {
        this.sentinelId = sentinelId;
        this.frameConsumer = frameConsumer;
    }

    public FrameListener() {
    }
}
