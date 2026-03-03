package at.ac.htlleonding.franklynserver.model;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class FramePayloadTest {

    @Test
    void constructor_setsAllFields() {
        FramePayload payload = new FramePayload("sentinel-1", "frame-1", 42, "base64data");

        assertThat(payload.sentinelId()).isEqualTo("sentinel-1");
        assertThat(payload.frameId()).isEqualTo("frame-1");
        assertThat(payload.index()).isEqualTo(42);
        assertThat(payload.data()).isEqualTo("base64data");
    }

    @Test
    void constructor_allowsNullValues() {
        FramePayload payload = new FramePayload(null, null, 0, null);

        assertThat(payload.sentinelId()).isNull();
        assertThat(payload.frameId()).isNull();
        assertThat(payload.index()).isZero();
        assertThat(payload.data()).isNull();
    }

    @Test
    void constructor_allowsEmptyStrings() {
        FramePayload payload = new FramePayload("", "", 0, "");

        assertThat(payload.sentinelId()).isEmpty();
        assertThat(payload.frameId()).isEmpty();
        assertThat(payload.data()).isEmpty();
    }

    @Test
    void constructor_allowsNegativeIndex() {
        FramePayload payload = new FramePayload("sentinel", "frame", -1, "data");

        assertThat(payload.index()).isEqualTo(-1);
    }

    @Test
    void equals_returnsTrueForSameValues() {
        FramePayload payload1 = new FramePayload("sentinel", "frame", 1, "data");
        FramePayload payload2 = new FramePayload("sentinel", "frame", 1, "data");

        assertThat(payload1).isEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentSentinelId() {
        FramePayload payload1 = new FramePayload("sentinel-1", "frame", 1, "data");
        FramePayload payload2 = new FramePayload("sentinel-2", "frame", 1, "data");

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentFrameId() {
        FramePayload payload1 = new FramePayload("sentinel", "frame-1", 1, "data");
        FramePayload payload2 = new FramePayload("sentinel", "frame-2", 1, "data");

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentIndex() {
        FramePayload payload1 = new FramePayload("sentinel", "frame", 1, "data");
        FramePayload payload2 = new FramePayload("sentinel", "frame", 2, "data");

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentData() {
        FramePayload payload1 = new FramePayload("sentinel", "frame", 1, "data1");
        FramePayload payload2 = new FramePayload("sentinel", "frame", 1, "data2");

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void hashCode_isSameForEqualObjects() {
        FramePayload payload1 = new FramePayload("sentinel", "frame", 1, "data");
        FramePayload payload2 = new FramePayload("sentinel", "frame", 1, "data");

        assertThat(payload1.hashCode()).isEqualTo(payload2.hashCode());
    }

    @Test
    void toString_containsAllFields() {
        FramePayload payload = new FramePayload("sentinel-1", "frame-1", 42, "base64data");

        String result = payload.toString();

        assertThat(result).contains("sentinel-1");
        assertThat(result).contains("frame-1");
        assertThat(result).contains("42");
        assertThat(result).contains("base64data");
    }
}
