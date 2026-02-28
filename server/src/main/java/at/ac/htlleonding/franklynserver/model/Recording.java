package at.ac.htlleonding.franklynserver.model;

import java.time.LocalDateTime;

public class Recording {
    private Long id;

    private Test test;

    private LocalDateTime startedAt;

    private LocalDateTime endedAt;

    private String studentName;

    private String videoFile;

    private String pcName;

    public Recording(Long id, Test test, LocalDateTime startedAt, LocalDateTime endedAt, String studentName, String videoFile, String pcName) {
        this.id = id;
        this.test = test;
        this.startedAt = startedAt;
        this.endedAt = endedAt;
        this.studentName = studentName;
        this.videoFile = videoFile;
        this.pcName = pcName;
    }
    public Recording() {

    }
}
