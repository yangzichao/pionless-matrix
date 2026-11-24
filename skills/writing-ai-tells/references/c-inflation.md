# C. Inflation and borrowed authority

The fact underneath is usually sound. Keep it and remove the dressing.

## 12. Overused AI words

**Watch for:** additionally, align with, bolstered, crucial, deep dive, delve, enduring, enhance, garner, gate/gated/gating (figurative; keep technical uses), highlight (verb), interplay, intricate/intricacies, key (adjective), landscape (abstract noun), meticulous/meticulously, pivotal, quietly, robust (figurative; keep technical uses), showcase, tapestry (abstract noun), testament, underscore (verb), valuable, vibrant

**Problem:** Models use these words far more often than people do, especially in clusters. One of them in plain, specific text is not a tell: a quarter of the best pre-2023 engineering posts contain one. Act on clusters: two in one paragraph, or about 3 per 1,000 words across the text. At that rate the words appear in 6% of the best posts and in about half of the AI-lab posts. Keep technical terms (advanced persistent threat, threat landscape, a key-value store). A formal word outside these lists is not a tell by itself.

**Before:**
> Additionally, a distinctive feature of Somali cuisine is the incorporation of camel meat. An enduring testament to Italian colonial influence is the widespread adoption of pasta in the local culinary landscape, showcasing how these dishes have integrated into the traditional diet.

**After:**
> Somali cuisine also includes camel meat, which is considered a delicacy. Pasta dishes, introduced during Italian colonization, remain common, especially in the south.

### Words that rose in engineering blogs after 2023

A study of 2,000 company engineering posts compared the same blogs before December 2022 (903 posts from 7 blogs) and from 2024 on (182 posts). Each word below appears in posts from at least 6 blogs and is several times more common after 2024. The numbers are the share of posts that use it at least once, before and after. AI topic words (model, agent, prompt) were filtered out.

| Word or phrase | Before | After |
|---|---|---|
| enhanced | 1% | 11% |
| proactive | 1% | 10% |
| a range of | 1% | 8% |
| tailored | 1% | 8% |
| delivers | 3% | 12% |
| optimized for | 2% | 11% |
| foundational | 3% | 12% |
| specialized | 3% | 12% |
| evolve | 6% | 21% |
| advanced | 9% | 27% |
| driven (as in "data-driven") | 6% | 21% |
| broader | 5% | 16% |
| targeted | 7% | 20% |
| "This includes..." opening a sentence | 2% | 10% |
| "This approach..." opening a sentence | 4% | 14% |

Comparing all pre-2023 posts (1,649) with all 2023-on posts including AI labs (329) adds: increasingly (7% to 21%), alongside (5% to 20%), consistently (4% to 15%), substantial (3% to 13%), systematically (2% to 9%), refine (2% to 9%), deliberately (1% to 8%), strengthen (1% to 7%).

These words follow the same cluster rule as the list above. The later posts are not known to be AI-written; the list shows the house style of the period, which AI drafts share.

Their replacements are the plain words the earlier posts used more: get ("to get" in 37% of posts before, 19% after), easy (35% to 19%), make sure (26% to 12%), a lot of (28% to 17%), wanted to (21% to 10%), hard to (13% to 5%), you can (48% to 32%). Usually the fix is the specific claim: "enhanced logging" becomes "logs now include the request ID".

## 13. Inflated significance

**Watch for:** stands as a testament, a pivotal or crucial moment, plays a key role, marking or shaping the, underscores its importance, reflects a broader, enduring or lasting legacy, setting the stage for, evolving landscape, indelible mark; Despite these challenges... continues to thrive, Challenges and Legacy, Future Outlook, Awards and recognition; the future looks bright, exciting times ahead, a step in the right direction

**Problem:** An ordinary detail is said to mark a change, prove a legacy, or promise a future. A short, specific look ahead is not this tell: "next we will shard the queue", a "What's next" section that names real plans, or one line of plain enthusiasm at the end of a company blog post ("we can't wait to see what you build"). Act when the significance has no fact under it. The habit shows up as a phrase, a stock "challenges and outlook" section, or a closing paragraph. Keep the fact and drop the significance. End on the last concrete fact, or on real plans if the source states them.

**Before:**
> The Statistical Institute of Catalonia was officially established in 1989, marking a pivotal moment in the evolution of regional statistics in Spain. This initiative was part of a broader movement across Spain to decentralize administrative functions and enhance regional governance.

**After:**
> The Statistical Institute of Catalonia was established in 1989 as part of a wider move across Spain to decentralize government work.

**Before (stock section):**
> Despite its industrial prosperity, Korattur faces challenges typical of urban areas, including traffic congestion and water scarcity. Despite these challenges, with its strategic location and ongoing initiatives, Korattur continues to thrive as an integral part of Chennai's growth.

**After:**
> Korattur has recurring traffic congestion and water shortages.

**Before (closing paragraph):**
> The future looks bright for the company. Exciting times lie ahead as they continue their journey toward excellence.

**After:**
> (Cut the paragraph. End on the last concrete fact.)

## 14. Vague connection or association

**Watch for:** associated with, in association with, connected to, in connection with, linked to, tied to

**Problem:** The text says two things are connected without saying how. "He was associated with the leadership of ExampleCorp" hides whether he was the CEO, a board member, or a consultant. Name the relationship. If you do not know it, keep the vague wording.

**Before:**
> He is associated with the Rajhans Orchestra, which he founded and conducts. The concerts were organised in connection with the celebrations of Pakistan's 50th anniversary.

**After:**
> He founded and conducts the Rajhans Orchestra. The concerts were part of the celebrations of Pakistan's 50th anniversary.

## 15. Shallow -ing phrases

**Watch for:** highlighting, underscoring, emphasizing, ensuring, reflecting, symbolizing, contributing to, cultivating, fostering, encompassing, showcasing

**Problem:** An -ing phrase is bolted onto a simple fact to make it sound deeper. Attaching it to a named source ("Roger Ebert highlighted the lasting influence") does not make it true. Keep the fact; keep the -ing phrase only when the source supports what it claims.

**Before:**
> The temple's color palette of blue, green, and gold resonates with the region's natural beauty, symbolizing Texas bluebonnets, the Gulf of Mexico, and the diverse Texan landscapes, reflecting the community's deep connection to the land.

**After:**
> The temple is painted blue, green, and gold to evoke Texas bluebonnets and the Gulf of Mexico.

## 16. Sales language

**Watch for:** rich (figurative), profound, exemplifies, commitment to, natural beauty, nestled, in the heart of, groundbreaking (figurative), renowned, featuring, diverse array, breathtaking, must-visit, stunning

**Problem:** The text reads like an advertisement, especially for places, culture, products, or organizations. State what the thing is.

**Before:**
> Nestled within the breathtaking region of Gonder in Ethiopia, Alamata Raya Kobo stands as a vibrant town with a rich cultural heritage and stunning natural beauty.

**After:**
> Alamata Raya Kobo is a town in the Gonder region of Ethiopia.

## 17. Borrowed authority

**Watch for:** experts argue, observers have cited, industry reports, some critics, several publications; cited, featured, or profiled in [a list of outlets], trade publications, independent coverage; active social media presence, over N followers

**Problem:** A name or an unnamed authority stands in for what was said. Unnamed experts prop up a claim; a list of prestige outlets props up a person. When you know the real source and what it said, name it. Otherwise cut the unsupported claim or the list. A missing citation alone is not a tell; most writing is unsourced.

**Before (unnamed authority):**
> Due to its unique characteristics, the Haolai River is of interest to researchers and conservationists. Experts believe it plays a crucial role in the regional ecosystem.

**After:**
> Researchers and conservationists study the Haolai River, often called the narrowest river in the world: it averages about 15 centimeters wide.

**Before (prestige list):**
> Her views have been cited in The New York Times, BBC, Financial Times, and The Hindu. She maintains an active social media presence with over 500,000 followers.

**After:**
> In a 2024 New York Times interview, she argued that AI regulation should focus on outcomes rather than methods.

## 18. Avoiding is, are, and has

**Watch for:** serves as, stands as, functions as, operates as, marks [a]; boasts, features [a]. "Represents" and "offers" in their literal sense (a diagram represents the values; the API offers two modes) are fine.

**Problem:** Simple verbs are replaced with longer phrases. Use *is*, *are*, and *has*.

**Before:**
> Gallery 825 serves as LAAA's exhibition space for contemporary art. The gallery features four separate spaces and boasts over 3,000 square feet.

**After:**
> Gallery 825 is LAAA's exhibition space for contemporary art. It has four separate spaces and more than 3,000 square feet.
