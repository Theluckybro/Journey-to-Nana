# Game Design Document (GDD)
## Project: Journey to Nana

> **Status:** **In Development** (Playable, active prototype)
> **Context:** This game is a personal, heartfelt project created by Indra as a special gift for his girlfriend, Nana. 

This document serves as the primary design reference for development. Implementation details may change based on iterations and playtest feedback.

## 1. Executive Summary
- **Genre:** Narrative, Slice of Life, 2D Pixel Art
- **Visuals:** Simple pixel art, chibi proportions
- **Platform:** PC (Windows)
- **Engine:** Godot Engine 4.x
- **Logline:** Follow the daily life of Indra, a college student, as he navigates his routines, interactions, and personal stories with his friends.

### Design Pillars
1. **Personal and Relatable Narrative:** Focuses on college life, friendship, and daily struggles.
2. **Simple Interactions:** Emphasizes a relaxing slice-of-life experience rather than complex mechanics.
3. **Realistic Scope:** A small number of in-game days, but packed with dense content and replayability through choices.

## 2. Core Gameplay Loop
The main cycle consists of:
1. Exploring the environment (dorm room, campus, etc.).
2. Interacting with objects (doors, buckets, cupboards, phones, PC, bed).
3. Completing daily quests (e.g., taking a bath, changing clothes, going to class).
4. Engaging in narrative dialogues (powered by Dialogic).
5. Experiencing timeskips (triggered automatically by events or manually).
6. Making dialogue/interaction choices that affect mood and story progression.

## 3. Core Systems
### 3.1 Quest System
- **Daily Quests:** Tasks like bathing, changing clothes, and attending lectures.
- **Dynamic Updates:** Objectives update seamlessly via object interactions.
- **Multiple Active Quests:** The system supports tracking and completing multiple quests simultaneously in the background.
- **UI & Notifications:** On-screen quest tracker and pop-up notifications (muted during save-loading).

### 3.2 Object Interaction
- Click/interact with key objects (Interactable Area2Ds with physical StaticBody2D boundaries).
- Conditional interactions (some objects are only active when specific quests are running).

### 3.3 Dialogic & Narrative
- Utilizes the Dialogic plugin for narration, monologues, and NPC conversations.
- Limited dialogue choices, some directly impacting the player's mood/story.
- Dialogues restrict player movement until completed.

### 3.4 Transitions & Timeskips
- **Timeskips:** Auto (events) and manual (via phone/bed) to control the day's pacing.
- **Visual Transitions:** Custom shader-based transitions, such as the "Iris Reveal" (Circle Transition) for smooth scene changes and new games.

### 3.5 Save & Load System
- Custom Resource-based save system (`SaveDataResource`).
- Persistently tracks player position, facing direction, coin amount, and all active quests across different scenes.

## 4. Day Structure & Example Events
- **Day 1:** Dorm room, taking a bath, changing clothes, leaving for campus, classroom narrative (timeskip), going home, ordering food, playing on the PC, sleeping.
- **Day 2:** Online interactions (chatting, Discord), meeting with Nana, plot twist, mood boost.

## 5. Asset & Audio Requirements
### 5.1 Visuals
- **Characters:** Indra, Nana, etc.
- **Environment:** Dorm room, campus, phone/PC UI.
- **UI:** Quest tracker, dialogue boxes, notifications, mood indicator.

### 5.2 Audio
- **SFX:** Alarm clocks, water splashing, phone notifications, mouse clicks, Discord sounds.
- **Music:** Daily looping BGM, transition tracks, ending themes.

## 6. MVP Production Scope
- 2 main days (Act 1: Surabaya, Day 1 & Day 2).
- Fully functional systems: Quests, object interactions, timeskips, Dialogic, and saving.
- Simple daily endings.

## 7. Definition of Done (Prototype)
1. One full day cycle is playable end-to-end without blockers.
2. Quest, interaction, Dialogic, and timeskip systems run consistently.
3. Quest and mood UIs are clearly readable.
4. Stable performance on mid-range PCs.

## 8. Risks & Mitigation
- **Risk:** Scope creep (adding too many days/features).
  - **Mitigation:** Lock the number of days and core features before expanding content.
- **Risk:** Narrative pacing is too slow/fast.
  - **Mitigation:** Daily playtesting, iterating on dialogue and timeskips.
- **Risk:** Inconsistent mood/quest balancing.
  - **Mitigation:** Centralized tuning tables, playtest feedback.

## 9. Technical Notes (Godot)
- Modular scene architecture for Player, NPCs, Quests, and Rooms.
- Custom Autoloads/Singletons used for `QuestManager`, `SaveLoad`, and `TransitionManager`.
- Heavy use of Custom Resources for scalable data management.