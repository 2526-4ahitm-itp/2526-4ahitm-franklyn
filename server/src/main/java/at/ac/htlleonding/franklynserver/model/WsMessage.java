package at.ac.htlleonding.franklynserver.model;

import com.fasterxml.jackson.annotation.JsonSetter;
import com.fasterxml.jackson.annotation.Nulls;

public record WsMessage(
        String type,
        long timestamp,
        @JsonSetter(nulls = Nulls.AS_EMPTY) Object payload
) {}