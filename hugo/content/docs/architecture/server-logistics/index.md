---
title: Server Class Diagram
date: 2025-11-27
---

```plantuml
@startuml

' Styling to make the diagram cleaner
skinparam classAttributeIconSize 0
skinparam linetype ortho

class Teacher {
    -id: Long
    -name: String
    ' OneToMany side
    +tests: List<Test>
}

class Test {
    -id: Long
    -title: String
    -startTime: LocalDateTime | null
    -endTime: LocalDateTime | null
    -testAccountPrefix: String
    ' ManyToOne side
    -teacher: Teacher
    ' OneToMany side
    -recordings: List<TestRecording>
}

class TestRecording {
    -id: Long
    -startedAt: LocalDateTime | null
    -endedAt: LocalDateTime | null
    ' ManyToOne side
    -student: Student
    ' OneToOne side (owning)
    -video: String
    -studentName: String
    -pcName: String
}

Teacher "1" <--> "0..*" Test : administers

Test "1" --> "0..*" TestRecording : contains

@enduml
```
