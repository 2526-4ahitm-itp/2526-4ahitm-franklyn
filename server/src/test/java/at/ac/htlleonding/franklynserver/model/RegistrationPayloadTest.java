package at.ac.htlleonding.franklynserver.model;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class RegistrationPayloadTest {

    @Test
    void constructor_setsAllFields() {
        RegistrationPayload payload = new RegistrationPayload("user-123", "johndoe");

        assertThat(payload.id()).isEqualTo("user-123");
        assertThat(payload.username()).isEqualTo("johndoe");
    }

    @Test
    void constructor_allowsNullValues() {
        RegistrationPayload payload = new RegistrationPayload(null, null);

        assertThat(payload.id()).isNull();
        assertThat(payload.username()).isNull();
    }

    @Test
    void equals_returnsTrueForSameValues() {
        RegistrationPayload payload1 = new RegistrationPayload("user-123", "johndoe");
        RegistrationPayload payload2 = new RegistrationPayload("user-123", "johndoe");

        assertThat(payload1).isEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentId() {
        RegistrationPayload payload1 = new RegistrationPayload("user-123", "johndoe");
        RegistrationPayload payload2 = new RegistrationPayload("user-456", "johndoe");

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentUsername() {
        RegistrationPayload payload1 = new RegistrationPayload("user-123", "johndoe");
        RegistrationPayload payload2 = new RegistrationPayload("user-123", "janedoe");

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void hashCode_sameForEqualObjects() {
        RegistrationPayload payload1 = new RegistrationPayload("user-123", "johndoe");
        RegistrationPayload payload2 = new RegistrationPayload("user-123", "johndoe");

        assertThat(payload1.hashCode()).isEqualTo(payload2.hashCode());
    }

    @Test
    void hashCode_differentForDifferentObjects() {
        RegistrationPayload payload1 = new RegistrationPayload("user-123", "johndoe");
        RegistrationPayload payload2 = new RegistrationPayload("user-456", "janedoe");

        assertThat(payload1.hashCode()).isNotEqualTo(payload2.hashCode());
    }

    @Test
    void toString_containsAllFields() {
        RegistrationPayload payload = new RegistrationPayload("user-123", "johndoe");
        String str = payload.toString();

        assertThat(str).contains("user-123");
        assertThat(str).contains("johndoe");
    }

    @Test
    void id_acceptsEmptyString() {
        RegistrationPayload payload = new RegistrationPayload("", "johndoe");

        assertThat(payload.id()).isEmpty();
    }

    @Test
    void username_acceptsEmptyString() {
        RegistrationPayload payload = new RegistrationPayload("user-123", "");

        assertThat(payload.username()).isEmpty();
    }

    @Test
    void username_acceptsSpecialCharacters() {
        RegistrationPayload payload = new RegistrationPayload("user-123", "john.doe@example.com");

        assertThat(payload.username()).isEqualTo("john.doe@example.com");
    }
}
