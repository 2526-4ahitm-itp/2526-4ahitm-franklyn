package at.ac.htlleonding.franklynserver.model;

import java.util.List;
import java.util.UUID;

public class Teacher {

    public Long id;

    public String name;

    public Teacher(Long id, String name) {
        this.id = id;
        this.name = name;
    }

    public Teacher() {
    }
}
