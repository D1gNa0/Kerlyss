# Technical Walkthrough: Discovery Hub Reactive Infrastructure

This document outlines the technical implementation of the state management layer for the Search Aggregator, integrating it into the presentation tier via Riverpod.

## 1. Objective and Requirements
The goal was to build the reactive plumbing connecting the UI to the dual-engine `SearchAggregator` without violating Clean Architecture boundaries. The primary focus was on performance and API conservation.

## 2. Implementation: `discoverySearchProvider`

### State Encapsulation
We introduced the `DiscoverySearchState` class to create a strictly immutable, single-source-of-truth object for the UI:
- `query` (String): The current active search terminology.
- `isLoading` (bool): Signals the UI to display processing animations.
- `results` (List<SongEntity>): The finalized, deduplicated output from the aggregator.
- `error` (String?): Graceful error handling for network contingencies.

### The Notifier (`DiscoverySearchNotifier`)
This class extends `StateNotifier` and manages the business logic for state transitions. 

#### Debounce Logic for API Conservation
To prevent "spamming" the public Spotify OEmbed endpoints and the YouTube search API while a user is typing, we implemented a **500ms Debounce Timer**.
1. When input is received (`onSearchQueryChanged`), the current timer (if active) is canceled.
2. A new Timer is spun up.
3. If the user stops typing for 500ms, the timer executes, calling `_performSearch`.

#### Race Condition Prevention
Inside `_performSearch`, we verify that `state.query == query && mounted`. This prevents a scenario where a delayed network response overwrites the results of a newer, subsequently fired search query.

## 3. Architectural Wiring

The UI will observe the `discoverySearchProvider`. This provider:
1. Injects the existing `songRepositoryProvider`.
2. Passes it down to the `DiscoverySearchNotifier`.

By routing through the repository, the Presentation Layer remains entirely agnostic of whether the data came from Isar, Spotify, or YouTube. The Search Aggregator handles the heavy lifting underneath.

---
**Documented by:** Senior Backend Developer (AI)
**Date:** 2026-04-10
**Status:** Discovery Hub Infrastructure Implementation Complete.
