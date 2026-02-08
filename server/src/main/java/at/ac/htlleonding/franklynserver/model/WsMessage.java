package at.ac.htlleonding.franklynserver.model;

public record WsMessage(String type, long timestamp, Object payload) {}