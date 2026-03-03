package at.ac.htlleonding.franklynserver.model;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class RegistrationRejectPayloadTest {

    @Test
    void constructor_setsReason() {
        RegistrationRejectPayload payload = new RegistrationRejectPayload("Username already taken");

        assertThat(payload.reason()).isEqualTo("Username already taken");
    }

    @Test
    void constructor_allowsNullReason() {
        RegistrationRejectPayload payload = new RegistrationRejectPayload(null);

        assertThat(payload.reason()).isNull();
    }

    @Test
    void constructor_allowsEmptyReason() {
        RegistrationRejectPayload payload = new RegistrationRejectPayload("");

        assertThat(payload.reason()).isEmpty();
    }

    @Test
    void equals_returnsTrueForSameReason() {
        RegistrationRejectPayload payload1 = new RegistrationRejectPayload("error");
        RegistrationRejectPayload payload2 = new RegistrationRejectPayload("error");

        assertThat(payload1).isEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentReason() {
        RegistrationRejectPayload payload1 = new RegistrationRejectPayload("error1");
        RegistrationRejectPayload payload2 = new RegistrationRejectPayload("error2");

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void hashCode_isSameForEqualObjects() {
        RegistrationRejectPayload payload1 = new RegistrationRejectPayload("error");
        RegistrationRejectPayload payload2 = new RegistrationRejectPayload("error");

        assertThat(payload1.hashCode()).isEqualTo(payload2.hashCode());
    }

    @Test
    void toString_containsReason() {
        RegistrationRejectPayload payload = new RegistrationRejectPayload("Invalid credentials");

        String result = payload.toString();

        assertThat(result).contains("Invalid credentials");
    }
}
