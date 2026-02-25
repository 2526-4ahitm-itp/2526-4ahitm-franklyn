package at.ac.htlleonding.franklynserver.model;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class FrameTest {

    @Test
    void constructor_setsAllFields() {
        Frame frame = new Frame("sentinel-1", "frame-1", 0, "base64data");

        assertThat(frame.sentinelId()).isEqualTo("sentinel-1");
        assertThat(frame.frameId()).isEqualTo("frame-1");
        assertThat(frame.index()).isEqualTo(0);
        assertThat(frame.data()).isEqualTo("base64data");
    }

    @Test
    void constructor_allowsNullValues() {
        Frame frame = new Frame(null, null, 0, null);

        assertThat(frame.sentinelId()).isNull();
        assertThat(frame.frameId()).isNull();
        assertThat(frame.data()).isNull();
    }

    @Test
    void equals_returnsTrueForSameValues() {
        Frame frame1 = new Frame("sentinel", "frame", 1, "data");
        Frame frame2 = new Frame("sentinel", "frame", 1, "data");

        assertThat(frame1).isEqualTo(frame2);
    }

    @Test
    void equals_returnsFalseForDifferentSentinelId() {
        Frame frame1 = new Frame("sentinel-1", "frame", 1, "data");
        Frame frame2 = new Frame("sentinel-2", "frame", 1, "data");

        assertThat(frame1).isNotEqualTo(frame2);
    }

    @Test
    void equals_returnsFalseForDifferentFrameId() {
        Frame frame1 = new Frame("sentinel", "frame-1", 1, "data");
        Frame frame2 = new Frame("sentinel", "frame-2", 1, "data");

        assertThat(frame1).isNotEqualTo(frame2);
    }

    @Test
    void equals_returnsFalseForDifferentIndex() {
        Frame frame1 = new Frame("sentinel", "frame", 1, "data");
        Frame frame2 = new Frame("sentinel", "frame", 2, "data");

        assertThat(frame1).isNotEqualTo(frame2);
    }

    @Test
    void equals_returnsFalseForDifferentData() {
        Frame frame1 = new Frame("sentinel", "frame", 1, "data1");
        Frame frame2 = new Frame("sentinel", "frame", 1, "data2");

        assertThat(frame1).isNotEqualTo(frame2);
    }

    @Test
    void hashCode_sameForEqualObjects() {
        Frame frame1 = new Frame("sentinel", "frame", 1, "data");
        Frame frame2 = new Frame("sentinel", "frame", 1, "data");

        assertThat(frame1.hashCode()).isEqualTo(frame2.hashCode());
    }

    @Test
    void hashCode_differentForDifferentObjects() {
        Frame frame1 = new Frame("sentinel-1", "frame", 1, "data");
        Frame frame2 = new Frame("sentinel-2", "frame", 1, "data");

        assertThat(frame1.hashCode()).isNotEqualTo(frame2.hashCode());
    }

    @Test
    void toString_containsAllFields() {
        Frame frame = new Frame("sentinel", "frame", 1, "data");
        String str = frame.toString();

        assertThat(str).contains("sentinel");
        assertThat(str).contains("frame");
        assertThat(str).contains("1");
        assertThat(str).contains("data");
    }

    @Test
    void index_acceptsNegativeValues() {
        Frame frame = new Frame("sentinel", "frame", -1, "data");

        assertThat(frame.index()).isEqualTo(-1);
    }

    @Test
    void index_acceptsMaxIntValue() {
        Frame frame = new Frame("sentinel", "frame", Integer.MAX_VALUE, "data");

        assertThat(frame.index()).isEqualTo(Integer.MAX_VALUE);
    }

    @Test
    void data_acceptsEmptyString() {
        Frame frame = new Frame("sentinel", "frame", 0, "");

        assertThat(frame.data()).isEmpty();
    }
}
