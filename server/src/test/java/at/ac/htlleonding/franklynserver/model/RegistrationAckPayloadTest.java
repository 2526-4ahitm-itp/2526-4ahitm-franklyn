package at.ac.htlleonding.franklynserver.model;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class RegistrationAckPayloadTest {

    @Test
    void constructor_setsProctorId() {
        RegistrationAckPayload payload = new RegistrationAckPayload("proctor-123");

        assertThat(payload.proctorId()).isEqualTo("proctor-123");
    }

    @Test
    void constructor_allowsNullProctorId() {
        RegistrationAckPayload payload = new RegistrationAckPayload(null);

        assertThat(payload.proctorId()).isNull();
    }

    @Test
    void equals_returnsTrueForSameProctorId() {
        RegistrationAckPayload payload1 = new RegistrationAckPayload("proctor-123");
        RegistrationAckPayload payload2 = new RegistrationAckPayload("proctor-123");

        assertThat(payload1).isEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentProctorId() {
        RegistrationAckPayload payload1 = new RegistrationAckPayload("proctor-123");
        RegistrationAckPayload payload2 = new RegistrationAckPayload("proctor-456");

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForNull() {
        RegistrationAckPayload payload = new RegistrationAckPayload("proctor-123");

        assertThat(payload).isNotEqualTo(null);
    }

    @Test
    void equals_returnsFalseForDifferentType() {
        RegistrationAckPayload payload = new RegistrationAckPayload("proctor-123");

        assertThat(payload).isNotEqualTo("proctor-123");
    }

    @Test
    void hashCode_sameForEqualObjects() {
        RegistrationAckPayload payload1 = new RegistrationAckPayload("proctor-123");
        RegistrationAckPayload payload2 = new RegistrationAckPayload("proctor-123");

        assertThat(payload1.hashCode()).isEqualTo(payload2.hashCode());
    }

    @Test
    void hashCode_differentForDifferentProctorIds() {
        RegistrationAckPayload payload1 = new RegistrationAckPayload("proctor-123");
        RegistrationAckPayload payload2 = new RegistrationAckPayload("proctor-456");

        assertThat(payload1.hashCode()).isNotEqualTo(payload2.hashCode());
    }

    @Test
    void toString_containsProctorId() {
        RegistrationAckPayload payload = new RegistrationAckPayload("proctor-123");
        String str = payload.toString();

        assertThat(str).contains("proctor-123");
    }

    @Test
    void proctorId_acceptsEmptyString() {
        RegistrationAckPayload payload = new RegistrationAckPayload("");

        assertThat(payload.proctorId()).isEmpty();
    }

    @Test
    void proctorId_acceptsUuidFormat() {
        String uuid = "550e8400-e29b-41d4-a716-446655440000";
        RegistrationAckPayload payload = new RegistrationAckPayload(uuid);

        assertThat(payload.proctorId()).isEqualTo(uuid);
    }
}
