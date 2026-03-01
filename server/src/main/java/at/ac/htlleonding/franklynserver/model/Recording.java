package at.ac.htlleonding.franklynserver.model;

import java.time.LocalDateTime;

public class Recording {
    public Long id;

    public Long testid;

    public LocalDateTime startedAt;

    public LocalDateTime endedAt;

    public String studentName;

    public String videoFile;

    public String pcName;

    public Recording(Long id, Long testid, LocalDateTime startedAt, LocalDateTime endedAt, String studentName, String videoFile, String pcName) {
        this.id = id;
        this.testid = testid;
        this.startedAt = startedAt;
        this.endedAt = endedAt;
        this.studentName = studentName;
        this.videoFile = videoFile;
        this.pcName = pcName;
    }
    public Recording() {

    }
}
