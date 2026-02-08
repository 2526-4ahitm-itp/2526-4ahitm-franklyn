package at.ac.htlleonding.franklynserver.cache;

import at.ac.htlleonding.franklynserver.model.Frame;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;

class CacheTest {

    @Test
    void getFrame_emptyWhenNothingSaved() {
        Cache cache = new Cache();
        UUID sentinelId = UUID.randomUUID();

        Optional<Frame> frame = cache.getFrame(sentinelId);

        assertThat(frame).isEmpty();
    }

    @Test
    void saveFrame_storesAndGetFrameReturnsLatest() {
        Cache cache = new Cache();
        UUID sentinelId = UUID.randomUUID();

        Frame frame1 = new Frame("sentinel", "frame-1", 1, "data-1");
        Frame frame2 = new Frame("sentinel", "frame-2", 2, "data-2");

        cache.saveFrame(frame1, sentinelId);
        assertThat(cache.getFrame(sentinelId)).containsSame(frame1);

        cache.saveFrame(frame2, sentinelId);
        assertThat(cache.getFrame(sentinelId)).containsSame(frame2);
    }

    @Test
    void registerOnFrame_notifiesListenerForMatchingSentinel() {
        Cache cache = new Cache();
        UUID sentinelId = UUID.randomUUID();

        AtomicReference<Frame> received = new AtomicReference<>();
        FrameListener listener = new FrameListener(sentinelId, received::set);
        cache.registerOnFrame(listener);

        Frame frame = new Frame("sentinel", "frame-1", 1, "data");
        cache.saveFrame(frame, sentinelId);

        assertThat(received.get()).isSameAs(frame);
    }

    @Test
    void registerOnFrame_doesNotNotifyForDifferentSentinel() {
        Cache cache = new Cache();
        UUID listenerSentinelId = UUID.randomUUID();
        UUID otherSentinelId = UUID.randomUUID();

        AtomicReference<Frame> received = new AtomicReference<>();
        FrameListener listener = new FrameListener(listenerSentinelId, received::set);
        cache.registerOnFrame(listener);

        Frame frame = new Frame("sentinel", "frame-1", 1, "data");
        cache.saveFrame(frame, otherSentinelId);

        assertThat(received.get()).isNull();
    }

    @Test
    void unregisterOnFrame_stopsNotifications() {
        Cache cache = new Cache();
        UUID sentinelId = UUID.randomUUID();

        AtomicReference<Frame> received = new AtomicReference<>();
        FrameListener listener = new FrameListener(sentinelId, received::set);
        cache.registerOnFrame(listener);
        cache.unregisterOnFrame(listener);

        Frame frame = new Frame("sentinel", "frame-1", 1, "data");
        cache.saveFrame(frame, sentinelId);

        assertThat(received.get()).isNull();
    }

    @Test
    void registerOnFrame_notifiesAllListenersForSameSentinel() {
        Cache cache = new Cache();
        UUID sentinelId = UUID.randomUUID();

        AtomicReference<Frame> received1 = new AtomicReference<>();
        AtomicReference<Frame> received2 = new AtomicReference<>();

        cache.registerOnFrame(new FrameListener(sentinelId, received1::set));
        cache.registerOnFrame(new FrameListener(sentinelId, received2::set));

        Frame frame = new Frame("sentinel", "frame-1", 1, "data");
        cache.saveFrame(frame, sentinelId);

        assertThat(received1.get()).isSameAs(frame);
        assertThat(received2.get()).isSameAs(frame);
    }
}
