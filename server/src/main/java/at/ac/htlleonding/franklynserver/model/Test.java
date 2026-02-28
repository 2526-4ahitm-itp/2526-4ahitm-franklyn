package at.ac.htlleonding.franklynserver.model;

import java.time.LocalDateTime;
import java.util.List;

public class Test {

    private Long id;

    private String title;

    private LocalDateTime startTime;

    private LocalDateTime endTime;

    private String testAccountPrefix;

    private Teacher teacher;

    public Test(Long id, String title, LocalDateTime startTime, LocalDateTime endTime, String testAccountPrefix, Teacher teacher) {
        this.id = id;
        this.title = title;
        this.startTime = startTime;
        this.endTime = endTime;
        this.testAccountPrefix = testAccountPrefix;
        this.teacher = teacher;
    }

    public Test() {

    }
}
