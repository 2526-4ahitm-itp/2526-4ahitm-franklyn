package at.ac.htlleonding.franklynserver.cache;

import at.ac.htlleonding.franklynserver.model.Frame;
import org.junit.jupiter.api.Test;

import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.Consumer;

import static org.assertj.core.api.Assertions.assertThat;

class FrameListenerTest {

    @Test
    void constructor_setsAllFields() {
        UUID sentinelId = UUID.randomUUID();
        Consumer<Frame> consumer = frame -> {};

        FrameListener listener = new FrameListener(sentinelId, consumer);

        assertThat(listener.sentinelId()).isEqualTo(sentinelId);
        assertThat(listener.frameConsumer()).isSameAs(consumer);
    }

    @Test
    void constructor_allowsNullValues() {
        FrameListener listener = new FrameListener(null, null);

        assertThat(listener.sentinelId()).isNull();
        assertThat(listener.frameConsumer()).isNull();
    }

    @Test
    void frameConsumer_acceptsFrame() {
        UUID sentinelId = UUID.randomUUID();
        AtomicReference<Frame> received = new AtomicReference<>();
        Consumer<Frame> consumer = received::set;

        FrameListener listener = new FrameListener(sentinelId, consumer);
        Frame frame = new Frame("sentinel", "frame-1", 1, "data");
        listener.frameConsumer().accept(frame);

        assertThat(received.get()).isSameAs(frame);
    }

    @Test
    void equals_returnsTrueForSameValues() {
        UUID sentinelId = UUID.randomUUID();
        Consumer<Frame> consumer = frame -> {};

        FrameListener listener1 = new FrameListener(sentinelId, consumer);
        FrameListener listener2 = new FrameListener(sentinelId, consumer);

        assertThat(listener1).isEqualTo(listener2);
    }

    @Test
    void equals_returnsFalseForDifferentSentinelId() {
        Consumer<Frame> consumer = frame -> {};

        FrameListener listener1 = new FrameListener(UUID.randomUUID(), consumer);
        FrameListener listener2 = new FrameListener(UUID.randomUUID(), consumer);

        assertThat(listener1).isNotEqualTo(listener2);
    }

    @Test
    void equals_returnsFalseForDifferentConsumer() {
        UUID sentinelId = UUID.randomUUID();

        FrameListener listener1 = new FrameListener(sentinelId, frame -> {});
        FrameListener listener2 = new FrameListener(sentinelId, frame -> {});

        assertThat(listener1).isNotEqualTo(listener2);
    }

    @Test
    void equals_returnsFalseForNull() {
        FrameListener listener = new FrameListener(UUID.randomUUID(), frame -> {});

        assertThat(listener).isNotEqualTo(null);
    }

    @Test
    void equals_returnsFalseForDifferentType() {
        FrameListener listener = new FrameListener(UUID.randomUUID(), frame -> {});

        assertThat(listener).isNotEqualTo("not a frame listener");
    }

    @Test
    void hashCode_sameForEqualObjects() {
        UUID sentinelId = UUID.randomUUID();
        Consumer<Frame> consumer = frame -> {};

        FrameListener listener1 = new FrameListener(sentinelId, consumer);
        FrameListener listener2 = new FrameListener(sentinelId, consumer);

        assertThat(listener1.hashCode()).isEqualTo(listener2.hashCode());
    }

    @Test
    void hashCode_differentForDifferentSentinelId() {
        Consumer<Frame> consumer = frame -> {};

        FrameListener listener1 = new FrameListener(UUID.randomUUID(), consumer);
        FrameListener listener2 = new FrameListener(UUID.randomUUID(), consumer);

        assertThat(listener1.hashCode()).isNotEqualTo(listener2.hashCode());
    }

    @Test
    void toString_containsAllFields() {
        UUID sentinelId = UUID.randomUUID();
        Consumer<Frame> consumer = frame -> {};

        FrameListener listener = new FrameListener(sentinelId, consumer);
        String str = listener.toString();

        assertThat(str).contains("FrameListener");
        assertThat(str).contains(sentinelId.toString());
    }

    @Test
    void sentinelId_returnsCorrectValue() {
        UUID sentinelId = UUID.randomUUID();

        FrameListener listener = new FrameListener(sentinelId, frame -> {});

        assertThat(listener.sentinelId()).isEqualTo(sentinelId);
    }

    @Test
    void frameConsumer_returnsCorrectValue() {
        Consumer<Frame> consumer = frame -> {};

        FrameListener listener = new FrameListener(UUID.randomUUID(), consumer);

        assertThat(listener.frameConsumer()).isSameAs(consumer);
    }
}
