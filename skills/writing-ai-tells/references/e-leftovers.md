# E. Leftovers from the chat and the draft

Remove these outright.

## 22. Chatbot residue

**Watch for:** I hope this helps, Of course!, Certainly!, Great question!, You're absolutely right, Would you like..., Want me to...?, Should I continue?, let me know, here is a...

**Problem:** A chatbot's greeting, praise, offer, or closing remains in text that should stand on its own. It is the clearest tell in this list and the easiest to miss when it wraps real content. Remove the wrapper and keep the content.

**Before:**
> Great question! Here is an overview of the French Revolution. It began in 1789 when a financial crisis and food shortages led to widespread unrest. I hope this helps! Let me know if you'd like me to expand on any section.

**After:**
> The French Revolution began in 1789 when a financial crisis and food shortages led to widespread unrest.

## 23. Knowledge-limit disclaimers and guesses

**Watch for:** as of [date], up to my last training update, while specific details are limited, based on available information, not publicly available, not widely documented or disclosed, in the provided or available sources, maintains a low profile, keeps personal details private, likely [grew up, studied, began], it is believed that

**Problem:** The text mentions where the model's knowledge ends, or admits it found no source and then fills the gap with a plausible guess. State what the source does not show, or cut the sentence.

**Before (cutoff disclaimer):**
> While specific details about the company's founding are not extensively documented in readily available sources, it appears to have been established sometime in the 1990s.

**After:**
> The sources do not give the company's founding date. (Or cut the sentence.)

**Before (guess):**
> Information about her early life is not publicly available, suggesting she maintains a low profile. She likely grew up in a middle-class household, which shaped her later interest in education reform.

**After:**
> The sources say nothing about her early life. (Or omit the section.)

## 24. A heading repeated in the first sentence

**Problem:** A heading is followed by a one-line paragraph that restates it before the real content begins. Remove the repeated sentence.

**Before:**
> ## Performance
>
> Speed matters.
>
> When users hit a slow page, they leave.

**After:**
> ## Performance
>
> When users hit a slow page, they leave.

## 25. Writing about the document instead of its subject

**Watch for:** what the text replaced ("was added to replace"); how it was assembled or sourced ("generated from", "compiled from", "anything unconfirmed is flagged rather than guessed"); a legend, layout, or order the reader can already see ("the table below compares", "this section is organized by owner").

**Problem:** The text describes itself instead of its subject. Mention a previous version only in change logs, release notes, migration guides, and other documents about change. Keep a source credit the reader can follow; cut the account of how you worked. Keep a caveat that changes what the reader should do. State a convention only when the reader cannot infer it, and state it once. A single description of the page is *weak alone*.

**Before:**
> This function was added to replace the previous approach of iterating through all items, which caused O(n²) performance.

**After:**
> This function uses a hash map for O(1) lookups, avoiding the O(n²) cost of iterating through every item.

**Before (method narration):**
> The figures below are drawn from each vendor's published pricing; anything we could not confirm is flagged rather than guessed.

**After:**
> Prices are each vendor's published rate. Two vendors publish nothing; call them.
