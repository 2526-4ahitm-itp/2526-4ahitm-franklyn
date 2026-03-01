package at.ac.htlleonding.franklynserver.model;

import java.time.LocalDateTime;
import java.util.List;

public class Test {

    public Long id;

    public String title;

    public LocalDateTime startTime;

    public LocalDateTime endTime;

    public String testAccountPrefix;

    public Long teacherid;

    public Test(Long id, String title, LocalDateTime startTime, LocalDateTime endTime, String testAccountPrefix, Long teacherid) {
        this.id = id;
        this.title = title;
        this.startTime = startTime;
        this.endTime = endTime;
        this.testAccountPrefix = testAccountPrefix;
        this.teacherid = teacherid;
    }

    public Test() {

    }
}
