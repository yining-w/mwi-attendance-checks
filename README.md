# Malawi Attendance Checks

> This is a simple repository which stores the coding file for attendance measurement checks
The input files are the high-frequency files shared by the field team.
> There are two output files per date:
- baseline_attendance_main.dta (clean/main variables)
- summary_DDMMYYYY.log (A log of any potential issues flagged by CGD team)
---

> [!NOTE]
> This repository does not contain any data. Is a remote file-sharing platform to track latest code versions for Data quality checks.do


## Directory structure

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
│   │   └── Data quality checks.do # <- this is a modular file that creates a new DDMMYY output per update in data
│   └── Monitoring 
└── README.md
```


---

---
## Flags for Review

| # | Date | EMIS | ISSUE | Action |
|---|-------|----------|------------|--------|
| 1 |24-09-26 | 500233 | STD2-A-P2, STD2-A-P3 are blurry |    |
| 1 |24-09-26 | 505348 | STD3-A-P1 is blurry |    |


## Flags for Note

| # | Date | EMIS | ISSUE | Action |
|---|-------|----------|------------|--------|
| 1 |24-09-26 | 505638 | Registries from previous academic year | Retake photos of registry at monitoring visit   |
| 1 |24-09-26 | 503154 | Floods/Rain season during monitoring visit | |

---

## 7. Change log

| Date       | Schools Added | 
|------------|--------|
| 26-09-26 |  6  |
