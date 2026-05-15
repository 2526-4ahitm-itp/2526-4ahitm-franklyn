package at.ac.htlleonding.franklynserver.config;

import io.smallrye.config.ConfigMapping;
import io.smallrye.config.WithDefault;

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
    }
}
