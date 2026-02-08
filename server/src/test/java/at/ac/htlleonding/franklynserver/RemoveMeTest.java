package at.ac.htlleonding.franklynserver;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

import io.quarkus.test.junit.QuarkusTest;

// Remove this test as soon as there is another QuarkusTest so this test is not needed anymore.
@QuarkusTest
public class RemoveMeTest {

    @Test
    void contextLoads() {
        // intentionally empty
        assertThat(1).isEqualTo(1);
    }
}
