package at.ac.htlleonding.franklynserver.config;

import io.smallrye.config.ConfigMapping;
import io.smallrye.config.WithDefault;

@ConfigMapping(prefix = "franklyn.pin")
public interface PinConfig {

    @WithDefault("1337")
    int min();

    @WithDefault("4200")
    int max();
}