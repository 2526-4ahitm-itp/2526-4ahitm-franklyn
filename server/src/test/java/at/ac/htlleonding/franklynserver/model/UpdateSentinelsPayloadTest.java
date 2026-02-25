package at.ac.htlleonding.franklynserver.model;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class UpdateSentinelsPayloadTest {

    @Test
    void constructor_setsSentinelsList() {
        List<String> sentinels = List.of("sentinel-1", "sentinel-2", "sentinel-3");
        UpdateSentinelsPayload payload = new UpdateSentinelsPayload(sentinels);

        assertThat(payload.sentinels()).hasSize(3);
        assertThat(payload.sentinels()).containsExactly("sentinel-1", "sentinel-2", "sentinel-3");
    }

    @Test
    void constructor_allowsNullList() {
        UpdateSentinelsPayload payload = new UpdateSentinelsPayload(null);

        assertThat(payload.sentinels()).isNull();
    }

    @Test
    void constructor_allowsEmptyList() {
        UpdateSentinelsPayload payload = new UpdateSentinelsPayload(Collections.emptyList());

        assertThat(payload.sentinels()).isEmpty();
    }

    @Test
    void equals_returnsTrueForSameSentinels() {
        List<String> sentinels = List.of("sentinel-1", "sentinel-2");
        UpdateSentinelsPayload payload1 = new UpdateSentinelsPayload(sentinels);
        UpdateSentinelsPayload payload2 = new UpdateSentinelsPayload(sentinels);

        assertThat(payload1).isEqualTo(payload2);
    }

    @Test
    void equals_returnsTrueForEqualSentinelLists() {
        UpdateSentinelsPayload payload1 = new UpdateSentinelsPayload(List.of("sentinel-1", "sentinel-2"));
        UpdateSentinelsPayload payload2 = new UpdateSentinelsPayload(List.of("sentinel-1", "sentinel-2"));

        assertThat(payload1).isEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentSentinels() {
        UpdateSentinelsPayload payload1 = new UpdateSentinelsPayload(List.of("sentinel-1"));
        UpdateSentinelsPayload payload2 = new UpdateSentinelsPayload(List.of("sentinel-2"));

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentOrder() {
        UpdateSentinelsPayload payload1 = new UpdateSentinelsPayload(List.of("sentinel-1", "sentinel-2"));
        UpdateSentinelsPayload payload2 = new UpdateSentinelsPayload(List.of("sentinel-2", "sentinel-1"));

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentListSizes() {
        UpdateSentinelsPayload payload1 = new UpdateSentinelsPayload(List.of("sentinel-1"));
        UpdateSentinelsPayload payload2 = new UpdateSentinelsPayload(List.of("sentinel-1", "sentinel-2"));

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void hashCode_sameForEqualObjects() {
        UpdateSentinelsPayload payload1 = new UpdateSentinelsPayload(List.of("sentinel-1", "sentinel-2"));
        UpdateSentinelsPayload payload2 = new UpdateSentinelsPayload(List.of("sentinel-1", "sentinel-2"));

        assertThat(payload1.hashCode()).isEqualTo(payload2.hashCode());
    }

    @Test
    void toString_containsSentinelInfo() {
        UpdateSentinelsPayload payload = new UpdateSentinelsPayload(List.of("sentinel-1"));
        String str = payload.toString();

        assertThat(str).contains("sentinels");
    }

    @Test
    void sentinels_preservesOrder() {
        List<String> sentinels = List.of("c-sentinel", "a-sentinel", "b-sentinel");
        UpdateSentinelsPayload payload = new UpdateSentinelsPayload(sentinels);

        assertThat(payload.sentinels().get(0)).isEqualTo("c-sentinel");
        assertThat(payload.sentinels().get(1)).isEqualTo("a-sentinel");
        assertThat(payload.sentinels().get(2)).isEqualTo("b-sentinel");
    }

    @Test
    void sentinels_withMutableList() {
        List<String> mutableSentinels = new ArrayList<>();
        mutableSentinels.add("sentinel-1");
        mutableSentinels.add("sentinel-2");
        UpdateSentinelsPayload payload = new UpdateSentinelsPayload(mutableSentinels);

        assertThat(payload.sentinels()).hasSize(2);
    }

    @Test
    void sentinels_allowsDuplicates() {
        List<String> sentinels = List.of("sentinel-1", "sentinel-1", "sentinel-2");
        UpdateSentinelsPayload payload = new UpdateSentinelsPayload(sentinels);

        assertThat(payload.sentinels()).hasSize(3);
        assertThat(payload.sentinels()).containsExactly("sentinel-1", "sentinel-1", "sentinel-2");
    }

    @Test
    void equals_handlesNullLists() {
        UpdateSentinelsPayload payload1 = new UpdateSentinelsPayload(null);
        UpdateSentinelsPayload payload2 = new UpdateSentinelsPayload(null);

        assertThat(payload1).isEqualTo(payload2);
    }
}
