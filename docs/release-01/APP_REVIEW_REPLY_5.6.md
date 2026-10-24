# Guideline 5.6 response — local draft, not sent

Use after reviewing the repair evidence. This local draft has not been sent. It does not claim that Apple identified the same source issue or that approval is guaranteed.

Hello App Review Team,

Thank you for reviewing Crown Tactics (皇冠戰略), version 1.1, build 1120. We take your concern about features appearing hidden during review seriously.

We checked the submitted description and Review Notes. They disclose the four heroes and their second skills, optional monsters and loot actions, three completed free matches, permanent non-consumable unlock and voluntary rewarded ads. These are the public game features. No game account or reviewer-specific login is required.

During our source audit and Release reconstruction, we found that internal fixture-loading and presentation/research tooling was still included in the Release compilation path, even though the normal product did not expose those engineering screens. We have prepared a repair that limits those tools to Debug compilation. The public game features remain available through normal navigation. We have also made the existing rewarded-ad access conditions explicit on the purchase screen from the first visit, without changing the three-match policy or purchase benefits.

We have uploaded and resubmitted version 1.1, build 1121, with a detailed feature walkthrough in Review Notes. The app and its non-consumable unlock are awaiting review. Release UI tests on iPhone and iPad simulators reach the public feature entries and the ad-choice screen by completing three normal local games, without special app launch arguments. We do not want to assume that these findings are the specific behavior you observed. Could you please identify the feature or screen considered hidden, the steps used to reach it, and the device/iOS version? A screenshot or recording would help us verify that the repaired build addresses your concern completely.

Thank you.
