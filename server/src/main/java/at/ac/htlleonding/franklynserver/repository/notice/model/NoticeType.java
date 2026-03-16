package at.ac.htlleonding.franklynserver.repository.notice.model;

public enum NoticeType {
    ALERT("alert"),
    TIMED("timed"),
    SINGLE("single");

    final String name;

    NoticeType(String name) {
        this.name = name;
    }
}
