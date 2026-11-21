# Dispute message

Send this to the user when you dispute at least one reviewer `must_fix` item. Then wait for their verdict on each disputed item.

```text
Reviewer (round {N}) raised {K} must_fix item(s). I dispute {M} of them — your call:

DISPUTED — please uphold or overturn each:
1. {file}:{line} — reviewer: "{issue}"
   my counter: "{counter-argument}"
2. ...

ACCEPTED (will fix without asking):
- {file}:{line} — {issue}
- ...
```

Omit the ACCEPTED section when every item is disputed.
