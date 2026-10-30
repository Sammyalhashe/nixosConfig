---
name: garmin-connect
description: Read the user's Garmin Connect fitness and health data (activities, sleep, HRV, stress, Body Battery, heart rate, steps, weight, hydration, nutrition). Use when the user asks about their workouts, training, sleep, recovery or other wearable metrics.
---

# Garmin Connect

Run `garmin <path>` to call the Garmin Connect Personal API. It handles
authentication and prints the JSON response. Never try to read or print the
API key or a token yourself.

The API is read-only. Dates are `YYYY-MM-DD` in the user's local time. Quote
paths that contain `?` or `&`.

```sh
garmin '/usersummary-service/usersummary/daily?calendarDate=2026-10-29' | jq .
garmin '/activitylist-service/activities/search/activities?limit=10' | jq '.[] | {activityName, startTimeLocal, distance, duration}'
```

Responses can be large. Pipe through `jq` to select the fields you need, and
summarize for the user instead of pasting raw JSON.

## Endpoints

Daily summaries and stats:

- `/usersummary-service/usersummary/daily?calendarDate=DATE`: one day's totals
- `/usersummary-service/v2/dailysummaries?startDate=DATE&endDate=DATE`
- `/usersummary-service/stats/steps/daily/START/END`
- `/usersummary-service/stats/stress/daily/START/END`
- `/usersummary-service/stats/hydration/daily/START/END`
- `/wellnessactivity-service/activity/summary/range/FROM/UNTIL`

Sleep, recovery and heart:

- `/sleep-service/sleep/dailySleep?date=DATE`
- `/sleep-service/sleep/dailySleepSummariesByDate?startDate=DATE&endDate=DATE`
- `/hrv-service/hrv/DATE`
- `/hrv-service/hrv/daily/FROM/TO`
- `/wellness-service/wellness/bodyBattery/reports/daily?startDate=DATE&endDate=DATE`
- `/wellness-service/wellness/dailyHeartRate?date=DATE`
- `/wellness-service/wellness/daily/spo2acclimation/DATE`
- `/biometric-service/heartRateZones/v2`
- `/fitnessage-service/fitnessage/v2/DATE`

Activities:

- `/activitylist-service/activities/search/activities`: filters include
  `start`, `limit`, `startDate`, `endDate`, `activityType`, `sortBy`,
  `sortOrder`, `search`, `minDistance`, `maxDistance`, `minDuration`,
  `maxDuration`
- `/activity-service/activity/ACTIVITY_ID`
- `/activity-service/activity/ACTIVITY_ID/workouts`
- `/download-service/files/activity/ACTIVITY_ID`: binary FIT file; redirect
  it to a file instead of printing it

Body, nutrition and profile:

- `/weight-service/weight/range/START/END`
- `/weight-service/weight/all/START/END`
- `/goal-service/goal/user/effective/weightgoal/START/END`
- `/nutrition-service/food/logs/DATE`
- `/userprofile-service/userprofile/settings`
