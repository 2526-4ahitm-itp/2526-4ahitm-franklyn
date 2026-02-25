package at.ac.htlleonding.franklynserver.model;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class WsMessageTest {

    @Test
    void constructor_setsAllFields() {
        WsMessage message = new WsMessage("FRAME", 1234567890L, "payload-data");

        assertThat(message.type()).isEqualTo("FRAME");
        assertThat(message.timestamp()).isEqualTo(1234567890L);
        assertThat(message.payload()).isEqualTo("payload-data");
    }

    @Test
    void constructor_allowsNullType() {
        WsMessage message = new WsMessage(null, 0L, "payload");

        assertThat(message.type()).isNull();
    }

    @Test
    void constructor_allowsNullPayload() {
        WsMessage message = new WsMessage("TYPE", 0L, null);

        assertThat(message.payload()).isNull();
    }

    @Test
    void constructor_allowsAllNullValues() {
        WsMessage message = new WsMessage(null, 0L, null);

        assertThat(message.type()).isNull();
        assertThat(message.timestamp()).isEqualTo(0L);
        assertThat(message.payload()).isNull();
    }

    @Test
    void payload_acceptsFramePayload() {
        FramePayload framePayload = new FramePayload("sentinel", "frame", 0, "data");
        WsMessage message = new WsMessage("FRAME", System.currentTimeMillis(), framePayload);

        assertThat(message.payload()).isInstanceOf(FramePayload.class);
        assertThat(message.payload()).isEqualTo(framePayload);
    }

    @Test
    void payload_acceptsRegistrationPayload() {
        RegistrationPayload registrationPayload = new RegistrationPayload("user-id", "username");
        WsMessage message = new WsMessage("REGISTRATION", System.currentTimeMillis(), registrationPayload);

        assertThat(message.payload()).isInstanceOf(RegistrationPayload.class);
        assertThat(message.payload()).isEqualTo(registrationPayload);
    }

    @Test
    void payload_acceptsMapPayload() {
        Map<String, Object> mapPayload = Map.of("key1", "value1", "key2", 123);
        WsMessage message = new WsMessage("CUSTOM", System.currentTimeMillis(), mapPayload);

        assertThat(message.payload()).isInstanceOf(Map.class);
    }

    @Test
    void payload_acceptsListPayload() {
        List<String> listPayload = List.of("item1", "item2", "item3");
        WsMessage message = new WsMessage("LIST_TYPE", System.currentTimeMillis(), listPayload);

        assertThat(message.payload()).isInstanceOf(List.class);
    }

    @Test
    void equals_returnsTrueForSameValues() {
        WsMessage message1 = new WsMessage("TYPE", 1000L, "payload");
        WsMessage message2 = new WsMessage("TYPE", 1000L, "payload");

        assertThat(message1).isEqualTo(message2);
    }

    @Test
    void equals_returnsFalseForDifferentType() {
        WsMessage message1 = new WsMessage("TYPE1", 1000L, "payload");
        WsMessage message2 = new WsMessage("TYPE2", 1000L, "payload");

        assertThat(message1).isNotEqualTo(message2);
    }

    @Test
    void equals_returnsFalseForDifferentTimestamp() {
        WsMessage message1 = new WsMessage("TYPE", 1000L, "payload");
        WsMessage message2 = new WsMessage("TYPE", 2000L, "payload");

        assertThat(message1).isNotEqualTo(message2);
    }

    @Test
    void equals_returnsFalseForDifferentPayload() {
        WsMessage message1 = new WsMessage("TYPE", 1000L, "payload1");
        WsMessage message2 = new WsMessage("TYPE", 1000L, "payload2");

        assertThat(message1).isNotEqualTo(message2);
    }

    @Test
    void equals_returnsFalseForNull() {
        WsMessage message = new WsMessage("TYPE", 1000L, "payload");

        assertThat(message).isNotEqualTo(null);
    }

    @Test
    void hashCode_sameForEqualObjects() {
        WsMessage message1 = new WsMessage("TYPE", 1000L, "payload");
        WsMessage message2 = new WsMessage("TYPE", 1000L, "payload");

        assertThat(message1.hashCode()).isEqualTo(message2.hashCode());
    }

    @Test
    void hashCode_differentForDifferentObjects() {
        WsMessage message1 = new WsMessage("TYPE1", 1000L, "payload");
        WsMessage message2 = new WsMessage("TYPE2", 2000L, "different");

        assertThat(message1.hashCode()).isNotEqualTo(message2.hashCode());
    }

    @Test
    void toString_containsAllFields() {
        WsMessage message = new WsMessage("FRAME", 1234567890L, "payload");
        String str = message.toString();

        assertThat(str).contains("FRAME");
        assertThat(str).contains("1234567890");
        assertThat(str).contains("payload");
    }

    @Test
    void timestamp_acceptsZero() {
        WsMessage message = new WsMessage("TYPE", 0L, "payload");

        assertThat(message.timestamp()).isEqualTo(0L);
    }

    @Test
    void timestamp_acceptsNegativeValue() {
        WsMessage message = new WsMessage("TYPE", -1L, "payload");

        assertThat(message.timestamp()).isEqualTo(-1L);
    }

    @Test
    void timestamp_acceptsMaxLongValue() {
        WsMessage message = new WsMessage("TYPE", Long.MAX_VALUE, "payload");

        assertThat(message.timestamp()).isEqualTo(Long.MAX_VALUE);
    }

    @Test
    void type_acceptsEmptyString() {
        WsMessage message = new WsMessage("", 1000L, "payload");

        assertThat(message.type()).isEmpty();
    }

    @Test
    void payload_acceptsNestedWsMessage() {
        WsMessage inner = new WsMessage("INNER", 500L, "inner-payload");
        WsMessage outer = new WsMessage("OUTER", 1000L, inner);

        assertThat(outer.payload()).isInstanceOf(WsMessage.class);
        assertThat(((WsMessage) outer.payload()).type()).isEqualTo("INNER");
    }

    @Test
    void equals_withComplexPayload() {
        FramePayload payload = new FramePayload("sentinel", "frame", 0, "data");
        WsMessage message1 = new WsMessage("FRAME", 1000L, payload);
        WsMessage message2 = new WsMessage("FRAME", 1000L, new FramePayload("sentinel", "frame", 0, "data"));

        assertThat(message1).isEqualTo(message2);
    }
}
