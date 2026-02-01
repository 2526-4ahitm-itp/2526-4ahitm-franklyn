package at.ac.htlleonding.franklynserver.cache;

import jakarta.inject.Inject;

import java.net.http.WebSocket;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

public class Cache {
    @Inject
    KeepFrame keepFrame;

    final int FRAME_DURATION = keepFrame.frame_duration();
    Map<Integer, String> frameMap = new HashMap<>();
    public static void main(String[] args) {

    }

    public synchronized void saveFrame(String jsonFrame, int webSocketId) {
        if (frameMap.containsKey(webSocketId)) {
            frameMap.replace(webSocketId, jsonFrame);
        } else {
         frameMap.put(webSocketId, jsonFrame);
        }
    }
    public Optional<String> returnFrame(int webSocketId) {
        return Optional.of(frameMap.get(webSocketId));
    }
}