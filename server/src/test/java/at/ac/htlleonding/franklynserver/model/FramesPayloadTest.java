package at.ac.htlleonding.franklynserver.model;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class FramesPayloadTest {

    @Test
    void constructor_setsFramesList() {
        List<Frame> frames = List.of(
                new Frame("sentinel-1", "frame-1", 0, "data1"),
                new Frame("sentinel-2", "frame-2", 1, "data2")
        );
        FramesPayload payload = new FramesPayload(frames);

        assertThat(payload.frames()).hasSize(2);
        assertThat(payload.frames()).isEqualTo(frames);
    }

    @Test
    void constructor_allowsNullList() {
        FramesPayload payload = new FramesPayload(null);

        assertThat(payload.frames()).isNull();
    }

    @Test
    void constructor_allowsEmptyList() {
        FramesPayload payload = new FramesPayload(Collections.emptyList());

        assertThat(payload.frames()).isEmpty();
    }

    @Test
    void equals_returnsTrueForSameFrames() {
        List<Frame> frames = List.of(new Frame("sentinel", "frame", 0, "data"));
        FramesPayload payload1 = new FramesPayload(frames);
        FramesPayload payload2 = new FramesPayload(frames);

        assertThat(payload1).isEqualTo(payload2);
    }

    @Test
    void equals_returnsTrueForEqualFrameLists() {
        FramesPayload payload1 = new FramesPayload(List.of(new Frame("sentinel", "frame", 0, "data")));
        FramesPayload payload2 = new FramesPayload(List.of(new Frame("sentinel", "frame", 0, "data")));

        assertThat(payload1).isEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentFrames() {
        FramesPayload payload1 = new FramesPayload(List.of(new Frame("sentinel-1", "frame", 0, "data")));
        FramesPayload payload2 = new FramesPayload(List.of(new Frame("sentinel-2", "frame", 0, "data")));

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentListSizes() {
        FramesPayload payload1 = new FramesPayload(List.of(new Frame("sentinel", "frame", 0, "data")));
        FramesPayload payload2 = new FramesPayload(List.of(
                new Frame("sentinel", "frame", 0, "data"),
                new Frame("sentinel", "frame", 1, "data")
        ));

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void hashCode_sameForEqualObjects() {
        List<Frame> frames = List.of(new Frame("sentinel", "frame", 0, "data"));
        FramesPayload payload1 = new FramesPayload(frames);
        FramesPayload payload2 = new FramesPayload(List.of(new Frame("sentinel", "frame", 0, "data")));

        assertThat(payload1.hashCode()).isEqualTo(payload2.hashCode());
    }

    @Test
    void toString_containsFrameInfo() {
        FramesPayload payload = new FramesPayload(List.of(new Frame("sentinel", "frame", 0, "data")));
        String str = payload.toString();

        assertThat(str).contains("frames");
    }

    @Test
    void frames_preservesOrder() {
        Frame frame1 = new Frame("sentinel-1", "frame-1", 0, "data1");
        Frame frame2 = new Frame("sentinel-2", "frame-2", 1, "data2");
        Frame frame3 = new Frame("sentinel-3", "frame-3", 2, "data3");
        List<Frame> frames = List.of(frame1, frame2, frame3);
        FramesPayload payload = new FramesPayload(frames);

        assertThat(payload.frames().get(0)).isEqualTo(frame1);
        assertThat(payload.frames().get(1)).isEqualTo(frame2);
        assertThat(payload.frames().get(2)).isEqualTo(frame3);
    }

    @Test
    void frames_withMutableList() {
        List<Frame> mutableFrames = new ArrayList<>();
        mutableFrames.add(new Frame("sentinel", "frame", 0, "data"));
        FramesPayload payload = new FramesPayload(mutableFrames);

        assertThat(payload.frames()).hasSize(1);
    }
}
