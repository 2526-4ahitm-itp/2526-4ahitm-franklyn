alter table fr_test rename to fr_exam;
alter index idx_fr_test_pin rename to idx_fr_exam_pin;
alter index idx_fr_test_teacher_id rename to idx_fr_exam_teacher_id;
alter table fr_exam rename constraint fr_test_pin_unique to fr_exam_pin_unique;
