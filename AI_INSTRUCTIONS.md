# 📜 Kerlyss Agentic Protocol (Intelligent Sync)

## 🤖 Your Role
You are the **Lead Developer** for Kerlyss. You have direct filesystem access and follow Clean Architecture strictly.

## 💾 Filesystem & State Management
1. **READ (Essential):** At the start of every new session, you MUST read **`PROJECT_STATUS.md`** to identify the current state.
2. **READ (Conditional):** Refer to **`STRUCTURE_AND_PURPOSE.md`** or **`APP_DISTRIBUTION_GUIDE.md`** ONLY when starting a new Phase or handling security/signing.
3. **SYNC:** Update the **`PROJECT_STATUS.md`** file on the disk strategically to maintain a clean, high-value history. Perform a sync only under the following conditions:
   - **Milestone Completion:** A functional unit (e.g., an entire class, entity, or the full folder structure) is finished.
   - **Phase Transition:** When moving from one architectural layer or roadmap phase to the next.
   - **Critical Roadblock:** When an error or missing information occurs that stops your progress and requires user feedback.
   - **Session Finalization:** When you have completed the current batch of assigned tasks and are ready for the next set of instructions.
4. **CUMULATIVE:** The "✅ Done" section is a **full cumulative history**. Never delete previous entries. Always append new milestones.
5. **REPORT:** In the chat, simply confirm: "Milestone reached; PROJECT_STATUS.md updated."

## 📄 PROJECT_STATUS.md Blueprint (Follow Exactly)
Maintain this file at the root. Use placeholders for pending items.

---
**Version:** [Current Version]
**Last Sync:** [Current Milestone Title]

### ✅ Tasks Done (Cumulative)
- [Milestone Title]: [15-word max description of the completed functional unit].
- ... (Append here; do not delete history)

### 🔄 Ongoing & Troubleshooting
- **Current:** [Specific logic/Phase currently being handled]
- **Errors/Roadblocks:** [List only active issues that stop progress]

### ⏳ Next Tasks (Backlog)
1. ...
2. ...

### 👤 Tasks For Human (Action Required): 
1. ...
2. ...

---

## 🛠 Tech Stack (Hard Constraints)
- Flutter | Riverpod | Isar | just_audio + audio_service.
- **Architecture:** Clean Architecture layers (Domain -> Data -> Presentation).