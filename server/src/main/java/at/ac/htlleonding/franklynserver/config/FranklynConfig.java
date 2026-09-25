package at.ac.htlleonding.franklynserver.config;

import io.smallrye.config.ConfigMapping;
import io.smallrye.config.WithDefault;
import jakarta.validation.constraints.Min;

@ConfigMapping(prefix = "franklyn")
public interface FranklynConfig {

    Pin pin();

    Video video();

    interface Pin {
        @WithDefault("1337")
        int min();

        @WithDefault("4200")
        int max();
    }

    interface Video {
        @WithDefault("/tmp/franklyn-videos")
        String storageDir();

        // 0 or less would move the cutoff to now or into the future and purge recordings of running exams
        @WithDefault("30")
        @Min(1)
        int retentionDays();
    }
}
