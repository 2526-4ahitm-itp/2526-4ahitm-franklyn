package at.ac.htlleonding.franklynserver.cache;

import at.ac.htlleonding.franklynserver.Frame;
import java.util.UUID;
import java.util.function.Consumer;

public record FrameListener(UUID sentinelId, Consumer<Frame> frameConsumer) {
}