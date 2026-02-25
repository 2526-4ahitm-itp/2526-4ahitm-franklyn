package at.ac.htlleonding.franklynserver.model;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class SubscriptionPayloadTest {

    @Test
    void constructor_setsSentinelId() {
        SubscriptionPayload payload = new SubscriptionPayload("sentinel-123");

        assertThat(payload.sentinelId()).isEqualTo("sentinel-123");
    }

    @Test
    void constructor_allowsNullSentinelId() {
        SubscriptionPayload payload = new SubscriptionPayload(null);

        assertThat(payload.sentinelId()).isNull();
    }

    @Test
    void equals_returnsTrueForSameSentinelId() {
        SubscriptionPayload payload1 = new SubscriptionPayload("sentinel-123");
        SubscriptionPayload payload2 = new SubscriptionPayload("sentinel-123");

        assertThat(payload1).isEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentSentinelId() {
        SubscriptionPayload payload1 = new SubscriptionPayload("sentinel-123");
        SubscriptionPayload payload2 = new SubscriptionPayload("sentinel-456");

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForNull() {
        SubscriptionPayload payload = new SubscriptionPayload("sentinel-123");

        assertThat(payload).isNotEqualTo(null);
    }

    @Test
    void equals_returnsFalseForDifferentType() {
        SubscriptionPayload payload = new SubscriptionPayload("sentinel-123");

        assertThat(payload).isNotEqualTo("sentinel-123");
    }

    @Test
    void hashCode_sameForEqualObjects() {
        SubscriptionPayload payload1 = new SubscriptionPayload("sentinel-123");
        SubscriptionPayload payload2 = new SubscriptionPayload("sentinel-123");

        assertThat(payload1.hashCode()).isEqualTo(payload2.hashCode());
    }

    @Test
    void hashCode_differentForDifferentSentinelIds() {
        SubscriptionPayload payload1 = new SubscriptionPayload("sentinel-123");
        SubscriptionPayload payload2 = new SubscriptionPayload("sentinel-456");

        assertThat(payload1.hashCode()).isNotEqualTo(payload2.hashCode());
    }

    @Test
    void toString_containsSentinelId() {
        SubscriptionPayload payload = new SubscriptionPayload("sentinel-123");
        String str = payload.toString();

        assertThat(str).contains("sentinel-123");
    }

    @Test
    void sentinelId_acceptsEmptyString() {
        SubscriptionPayload payload = new SubscriptionPayload("");

        assertThat(payload.sentinelId()).isEmpty();
    }

    @Test
    void sentinelId_acceptsUuidFormat() {
        String uuid = "550e8400-e29b-41d4-a716-446655440000";
        SubscriptionPayload payload = new SubscriptionPayload(uuid);

        assertThat(payload.sentinelId()).isEqualTo(uuid);
    }

    @Test
    void equals_handlesNullSentinelIds() {
        SubscriptionPayload payload1 = new SubscriptionPayload(null);
        SubscriptionPayload payload2 = new SubscriptionPayload(null);

        assertThat(payload1).isEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForNullVsNonNull() {
        SubscriptionPayload payload1 = new SubscriptionPayload(null);
        SubscriptionPayload payload2 = new SubscriptionPayload("sentinel-123");

        assertThat(payload1).isNotEqualTo(payload2);
    }
}
