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
    void constructor_allowsEmptyStrings() {
        RegistrationPayload payload = new RegistrationPayload("", "");

        assertThat(payload.id()).isEmpty();
        assertThat(payload.username()).isEmpty();
    }

    @Test
    void equals_returnsTrueForSameValues() {
        RegistrationPayload payload1 = new RegistrationPayload("id-1", "user");
        RegistrationPayload payload2 = new RegistrationPayload("id-1", "user");

        assertThat(payload1).isEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentId() {
        RegistrationPayload payload1 = new RegistrationPayload("id-1", "user");
        RegistrationPayload payload2 = new RegistrationPayload("id-2", "user");

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void equals_returnsFalseForDifferentUsername() {
        RegistrationPayload payload1 = new RegistrationPayload("id-1", "user1");
        RegistrationPayload payload2 = new RegistrationPayload("id-1", "user2");

        assertThat(payload1).isNotEqualTo(payload2);
    }

    @Test
    void hashCode_isSameForEqualObjects() {
        RegistrationPayload payload1 = new RegistrationPayload("id-1", "user");
        RegistrationPayload payload2 = new RegistrationPayload("id-1", "user");

        assertThat(payload1.hashCode()).isEqualTo(payload2.hashCode());
    }

    @Test
    void toString_containsAllFields() {
        RegistrationPayload payload = new RegistrationPayload("user-123", "johndoe");

        String result = payload.toString();

        assertThat(result).contains("user-123");
        assertThat(result).contains("johndoe");
    }
}
