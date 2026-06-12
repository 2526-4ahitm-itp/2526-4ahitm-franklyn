---
title: Preparing Students
description: Help students get set up with Franklyn Sentinel before the exam
weight: 30
---

Students need to have Franklyn Sentinel installed before the exam. If you are running your own server, they also need to configure which server to connect to.

If you are unsure which server you are connected to, you can look at the URL in the browser when on the proctor site.

For example if you see
`https://franklyn3.htl-leonding.ac.at/proctor/exams/`

then the URL for students will be:
`franklyn3.htl-leonding.ac.at/api`

---

**Franklyn Setup**

Enter the following in the terminal to configure which server to connect to (skip if using `franklyn.htl-leonding.ac.at`):

```shell
franklyn config set api_url "franklyn3.htl-leonding.ac.at/api"
```

Enter the following in the terminal to join the exam with the PIN provided by your teacher:

```shell
franklyn join <pin>
```