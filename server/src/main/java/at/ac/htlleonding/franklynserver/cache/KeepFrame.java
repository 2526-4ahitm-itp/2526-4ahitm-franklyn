package at.ac.htlleonding.franklynserver.cache;

import io.smallrye.config.ConfigMapping;

@ConfigMapping(prefix = "franklyn")
public interface KeepFrame {
    int frame_duration();
}
