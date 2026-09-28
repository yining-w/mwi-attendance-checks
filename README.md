# Malawi Attendance Checks

> This is a simple repository which stores the coding file for attendance measurement checks
The input files are the high-frequency files shared by the field team.
> There are two output files per date:
- baseline_attendance_main.dta (clean/main variables)
- summary_DDMMYYYY.log (A log of any potential issues flagged by CGD team)
---

> [!NOTE]
> This repository does not contain any data. Is a remote file-sharing platform to track latest code versions for Data quality checks.do


## Internal Directory structure

```
../1. Data
├── 1. Raw/                     # Raw data — never edit by hand
│   ├── Baseline/
│   │   └── DDMMYY/
│   │       ├── baseline_attendance_form.dta # <-- input
|   |       ├── baseline_attendance_main.dta # <-- output
|   |       ├── summary_DDMMYYYY.log # <-- output
│   │       └── register_scans/
│   │           ├── media/          # Original SurveyCTO media
│   │           └── media_renamed/  # Copy of the above, renamed to identify EMIS and streams
│   └── MV1/
../2. Dofiles
├── MASTER.do                     
│   ├── Baseline/ 
│   │   └── Data quality checks.do # <- this is a modular file that creates a new DDMMYY output per update in data (this is the only file available in this repo)
│   └── Monitoring 
└── README.md
```


---

---

## 7. Change log

| Date       | Schools Added | 
|------------|--------|
| 26-09-26 |  6  |
