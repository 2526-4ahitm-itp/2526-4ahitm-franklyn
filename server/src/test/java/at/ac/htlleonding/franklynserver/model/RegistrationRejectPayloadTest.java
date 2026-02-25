package at.ac.htlleonding.franklynserver.model;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class RegistrationRejectPayloadTest {

    @Test
    void constructor_setsReason() {
        RegistrationRejectPayload payload = new RegistrationRejectPayload("Invalid credentials");

        assertThat(payload.reason()).isEqualTo("Invalid credentials");
    }

    @Test
    void constructor_allowsNullReason() {
        RegistrationRejectPayload payload = new RegistrationRejectPayload(null);

        assertThat(payload.reason()).isNull();
    }

    @Test
    void equals_returnsTrueForSameReason() {
        RegistrationRejectPayload payload1 = new RegistrationRejectPayload("User not found");
        RegistrationRejectPayload payload2 = new RegistrationRejectPayload("User not found");

        assertThat(payload1).isEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentReason() {
        RegistrationRejectPayload payload1 = new RegistrationRejectPayload("User not found");
        RegistrationRejectPayload payload2 = new RegistrationRejectPayload("Session expired");

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForNull() {
        RegistrationRejectPayload payload = new RegistrationRejectPayload("Error");

        assertThat(payload).isNotEqualTo(null);
    }

    @Test
    void equals_returnsFalseForDifferentType() {
        RegistrationRejectPayload payload = new RegistrationRejectPayload("Error");

        assertThat(payload).isNotEqualTo("Error");
    }

    @Test
    void hashCode_sameForEqualObjects() {
        RegistrationRejectPayload payload1 = new RegistrationRejectPayload("Error");
        RegistrationRejectPayload payload2 = new RegistrationRejectPayload("Error");

        assertThat(payload1.hashCode()).isEqualTo(payload2.hashCode());
    }

    @Test
    void hashCode_differentForDifferentReasons() {
        RegistrationRejectPayload payload1 = new RegistrationRejectPayload("Error 1");
        RegistrationRejectPayload payload2 = new RegistrationRejectPayload("Error 2");

        assertThat(payload1.hashCode()).isNotEqualTo(payload2.hashCode());
    }

    @Test
    void toString_containsReason() {
        RegistrationRejectPayload payload = new RegistrationRejectPayload("Access denied");
        String str = payload.toString();

        assertThat(str).contains("Access denied");
    }

    @Test
    void reason_acceptsEmptyString() {
        RegistrationRejectPayload payload = new RegistrationRejectPayload("");

        assertThat(payload.reason()).isEmpty();
    }

    @Test
    void reason_acceptsLongMessage() {
        String longReason = "A".repeat(1000);
        RegistrationRejectPayload payload = new RegistrationRejectPayload(longReason);

        assertThat(payload.reason()).hasSize(1000);
    }

    @Test
    void reason_acceptsMultilineMessage() {
        String multilineReason = "Error occurred.\nPlease try again.";
        RegistrationRejectPayload payload = new RegistrationRejectPayload(multilineReason);

        assertThat(payload.reason()).contains("\n");
    }
}
