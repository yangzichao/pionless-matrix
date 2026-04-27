## 3. Shared Fragments

> **Status: decided against.** Skills do not share prompt content. Duplicated content is physically copied into each skill folder.
>
> **Reason.** A skill folder must be directly loadable with no preprocessing. That kills build-time includes (need a build), runtime reads of shared paths (break when a skill is installed standalone), and symlinks (not portable). Physical duplication is what remains. Drift is an authoring concern.
