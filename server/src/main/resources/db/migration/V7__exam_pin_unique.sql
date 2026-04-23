-- IMPORTANT: To apply this migration without errors, the database has to be dropped.

alter table fr_test alter column pin set not null;

alter table fr_test add constraint fr_test_pin_unique unique (pin);