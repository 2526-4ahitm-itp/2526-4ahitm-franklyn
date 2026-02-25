package at.ac.htlleonding.franklynserver.model;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class SentinelAckPayloadTest {

    @Test
    void constructor_setsSentinelId() {
        SentinelAckPayload payload = new SentinelAckPayload("sentinel-123");

        assertThat(payload.sentinelId()).isEqualTo("sentinel-123");
    }

    @Test
    void constructor_allowsNullSentinelId() {
        SentinelAckPayload payload = new SentinelAckPayload(null);

        assertThat(payload.sentinelId()).isNull();
    }

    @Test
    void equals_returnsTrueForSameSentinelId() {
        SentinelAckPayload payload1 = new SentinelAckPayload("sentinel-123");
        SentinelAckPayload payload2 = new SentinelAckPayload("sentinel-123");

        assertThat(payload1).isEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentSentinelId() {
        SentinelAckPayload payload1 = new SentinelAckPayload("sentinel-123");
        SentinelAckPayload payload2 = new SentinelAckPayload("sentinel-456");

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForNull() {
        SentinelAckPayload payload = new SentinelAckPayload("sentinel-123");

        assertThat(payload).isNotEqualTo(null);
    }

    @Test
    void equals_returnsFalseForDifferentType() {
        SentinelAckPayload payload = new SentinelAckPayload("sentinel-123");

        assertThat(payload).isNotEqualTo("sentinel-123");
    }

    @Test
    void hashCode_sameForEqualObjects() {
        SentinelAckPayload payload1 = new SentinelAckPayload("sentinel-123");
        SentinelAckPayload payload2 = new SentinelAckPayload("sentinel-123");

        assertThat(payload1.hashCode()).isEqualTo(payload2.hashCode());
    }

    @Test
    void hashCode_differentForDifferentSentinelIds() {
        SentinelAckPayload payload1 = new SentinelAckPayload("sentinel-123");
        SentinelAckPayload payload2 = new SentinelAckPayload("sentinel-456");

        assertThat(payload1.hashCode()).isNotEqualTo(payload2.hashCode());
    }

    @Test
    void toString_containsSentinelId() {
        SentinelAckPayload payload = new SentinelAckPayload("sentinel-123");
        String str = payload.toString();

        assertThat(str).contains("sentinel-123");
    }

    @Test
    void sentinelId_acceptsEmptyString() {
        SentinelAckPayload payload = new SentinelAckPayload("");

        assertThat(payload.sentinelId()).isEmpty();
    }

    @Test
    void sentinelId_acceptsUuidFormat() {
        String uuid = "550e8400-e29b-41d4-a716-446655440000";
        SentinelAckPayload payload = new SentinelAckPayload(uuid);

        assertThat(payload.sentinelId()).isEqualTo(uuid);
    }
}
