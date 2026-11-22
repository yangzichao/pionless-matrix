# During implementation: the deviation log

However good the plan, the code holds surprises. Log each one when it happens, not at the end, so the next attempt and the reviewer inherit what you learned.

## Procedure

1. **Log every deviation as it happens.** A deviation is any place the code forced you away from the plan: an assumption turned out false, an API behaves differently from what the plan expected, a file is not where the plan said, or the plan did not cover a decision you had to make.

2. **Write each entry in four parts:**
   - **Plan said:** the line of the plan, or "plan is silent".
   - **Code showed:** file and line, or the command and its output.
   - **Call made:** what you did. Prefer the conservative call: the smallest change that keeps existing behaviour and is easy to reverse.
   - **Review:** yes if the call changes a public interface, stored data, or scope; otherwise no.

3. **Stop and ask the user instead of choosing** when the call would change data on disk or in production, change a public interface, go beyond the plan's scope, or could not be undone.

4. **Keep the log where it will be read:** a notes section in the plan file if there is one, a file the user named, or otherwise the end of your reply.

5. **At the end, write the summary:** the entries marked for review first, then at most three lines under "fold into the next plan" saying what the plan should have said.

## Output shape

```markdown
## Deviation log
1. Plan said: <line or "plan is silent">
   Code showed: <file:line or command output>
   Call made: <what you did>
   Review: yes | no

## For review
- <entry numbers, with one line each on why>

## Fold into the next plan
- <what the plan should have said>
```

## Example

```markdown
## Deviation log
1. Plan said: "reuse `parse_date` from utils".
   Code showed: `utils/dates.py:14` parses in local time; the import data is UTC.
   Call made: added `parse_date_utc` next to it; left `parse_date` unchanged.
   Review: no
2. Plan said: plan is silent on rows with no email.
   Code showed: 312 of the sample rows have an empty email; the `users.email` column is NOT NULL (`schema.sql:40`).
   Call made: stopped and asked; the user chose to skip such rows and report them.
   Review: yes

## For review
- 2: skipped rows are a behaviour the importer never had.

## Fold into the next plan
- State the timezone of every date field.
- Say what happens to rows that break a constraint.
```
