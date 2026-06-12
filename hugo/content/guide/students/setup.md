---
title: Setup
description: Configure Franklyn Sentinel and join an exam
weight: 20
---

## Configure the Server

> If your teacher is using the default server (`franklyn.htl-leonding.ac.at`), skip this step.

If your exam runs on a different server, enter the following in the terminal to set the server address once before joining, just like configuring your git username and email at the start of an exam.

```shell
franklyn config set api_url "franklyn3.htl-leonding.ac.at/api"
```

Replace `franklyn3.htl-leonding.ac.at` with the server your teacher specifies.

## Join the Exam

Enter the following in the terminal to join the exam with the PIN your teacher provides:

```shell
franklyn join <pin>
```

Example: `franklyn join 1234`
