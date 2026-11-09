---
name: ntfy-notify
description: Send a push notification to the user's phone through ntfy. Use it to deliver the results of recurring (cron) jobs, reminders and alerts, instead of replying in Telegram. Normal conversations still reply in Telegram.
---

# ntfy notifications

Run `notify "<title>" "<message>" [tags]` to push a notification to the user's
phone on the `hermes` ntfy topic. It handles authentication; never try to read
or print a token yourself. It prints `sent` on success.

- `title`: short, specific, under 60 characters, e.g. `Market momentum: BTC breakout`.
- `message`: the result itself, in Markdown. Lead with the conclusion; keep it
  under about 3,000 characters. Longer content is attached as a file
  automatically.
- `tags` (optional): comma-separated ntfy emoji tags, e.g. `chart_with_upwards_trend`,
  `alarm_clock`, `email`, `warning`. Defaults to `robot`.

## When to use it

- **Recurring jobs:** deliver the job's result with `notify` as its final step.
  Such jobs are configured with `deliver: local`, so nothing is posted to
  Telegram; the notification is the delivery.
- **Reminders:** a one-line `notify` is the whole job, e.g.
  `notify "Wind-down" "Time to start winding down for bed." alarm_clock`.

If `notify` fails, report the error in the job's output; do not fall back to
Telegram.
