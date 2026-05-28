# Proctor Style and Layout Cleanup Plan

This document details layout and style inconsistencies (violations of the design token mentality outlined in `rewrite.md` and `AGENTS.md`) found in the `proctor/` codebase, along with their resolutions.

---

## 1. Identified Violations

### 1.1 Inconsistent Page Width & Layout Wrapper
* **SettingsView.vue (`.settings-view`)**: Uses its own custom width (`width: min(92%, 760px)`) and padding (`padding: 2.25rem 0 3rem`), which makes it look visually disconnected from the rest of the application. It should use the shared `.view-management` layout wrapper pattern (`width: min(95%, var(--body-base-width))`, `max-width: 1200px`, `margin: 0 auto`, `padding: var(--space-10)`) to align with `HomeView.vue` and others.

### 1.2 Hardcoded Spacing (Padding, Margin, Gap)
* **components/ui/Dialog.vue (`.dialog-content`)**: Uses hardcoded `padding: 24px` instead of `var(--space-6)`.
* **components/ui/Card.vue (`.card`)**: Uses hardcoded `padding: 20px` instead of `var(--space-5)`.
* **components/ui/Badge.vue (`.badge`)**: Uses hardcoded `padding: 8px 16px` instead of `var(--space-2) var(--space-4)`.
* **ConfirmDialog.vue (`.dialog-description` & `.modal-actions`)**:
  * Uses hardcoded `margin-bottom: 24px` (should be `var(--space-6)`).
  * Uses hardcoded `gap: 8px` (should be `var(--space-2)`) and `margin-top: 20px` (should be `var(--space-5)`).
* **ExamRow.vue (`.exam-row` & `.exam-details` & `.exam-title-row` & `.exam-meta-row`)**:
  * Uses hardcoded `padding: 20px 24px` (should be `var(--space-5) var(--space-6)`).
  * Uses hardcoded `gap: 8px` (should be `var(--space-2)`) and `gap: 12px` (should be `var(--space-3)`).
* **ExamStatusFilter.vue (`.filter-pills` & `.filter-pill`)**:
  * Uses hardcoded `gap: 10px` (should be `var(--space-2)` or `var(--space-3)`).
  * Uses hardcoded `margin-bottom: 24px` (should be `var(--space-6)`).
  * Uses hardcoded `padding: 8px 18px` (should be `var(--space-2) var(--space-4)` or similar scale).
* **ExpandedSentinelOverlay.vue (`.overlay-close`)**:
  * Uses hardcoded positioning: `top: 0.25rem; right: 0.5rem;` (should be `var(--space-1)` and `var(--space-2)`).
  * Uses hardcoded padding: `padding: 0.1rem 0.35rem;`.
* **NewExamDialog.vue (`.form-row` & `.modal-actions`)**:
  * Uses hardcoded `gap: 12px` (should be `var(--space-3)`).
  * Uses hardcoded `gap: 8px` (should be `var(--space-2)`).
* **HomeView.vue (`.view-management`, `.section-header`, `.exam-list`)**:
  * Uses hardcoded `padding: 40px` (should be `var(--space-10)`).
  * Uses hardcoded `margin-bottom: 20px` (should be `var(--space-5)`).
  * Uses hardcoded `gap: 12px` (should be `var(--space-3)`).
* **AdminNoticeBannersView.vue (`.view-management`, `.section-header`, `.notice-row`, etc.)**:
  * Uses hardcoded `padding: 40px` (should be `var(--space-10)`).
  * Uses hardcoded `margin-bottom: 20px` (should be `var(--space-5)`).
  * Uses hardcoded `gap: 12px` (should be `var(--space-3)`).
  * Uses hardcoded `padding: 20px 24px` (should be `var(--space-5) var(--space-6)`).
  * Uses hardcoded `gap: 8px` (should be `var(--space-2)`), `gap: 12px` (should be `var(--space-3)`), etc.
  * Mobile media query uses hardcoded `padding: 20px` (should be `var(--space-5)`).
* **ExamDetailView.vue (`.view-management`, `.top-bar`, `.header-main`, `.back-btn`, `.status-pill`, etc.)**:
  * Uses hardcoded `padding: 32px 40px` (should be `var(--space-8) var(--space-10)`).
  * Uses hardcoded `margin-bottom: 32px` (should be `var(--space-8)`).
  * Uses hardcoded `gap: 12px` (should be `var(--space-3)`), `margin-bottom: 8px` (should be `var(--space-2)`).
  * Uses hardcoded `width: 32px; height: 32px;` for back button (should be `var(--space-8)`).
  * Uses hardcoded `gap: 6px` for status pill (should be `var(--space-1.5)` or `var(--space-2)`).
  * Uses hardcoded `padding: 4px 10px` for status pill (should be `var(--space-1) var(--space-2.5)`).
  * Uses hardcoded `width: 6px; height: 6px;` for status dot (should be `var(--space-1.5)`).
  * Uses hardcoded `gap: 8px` (should be `var(--space-2)`).
  * Uses hardcoded `gap: 20px` (should be `var(--space-5)`).
  * Uses hardcoded card title margins: `margin: 0 0 16px` (should be `margin: 0 0 var(--space-4)`).
  * Uses hardcoded session row padding: `padding: 10px 14px` (should be `var(--space-2.5) var(--space-3.5)` or similar).
  * Uses hardcoded right panel gaps: `gap: 16px` (should be `var(--space-4)`).
  * Uses hardcoded info row padding: `padding: 8px 0` (should be `var(--space-2) 0`).
  * Uses hardcoded info dates gap: `gap: 2px` (should be `var(--space-0.5)`).
  * Uses hardcoded status badge padding: `padding: 2px 8px` (should be `var(--space-0.5) var(--space-2)`).
  * Uses hardcoded action buttons gap: `gap: 8px` (should be `var(--space-2)`).
  * Uses hardcoded loading state margin-top: `margin-top: 50px` (should be `var(--space-12)` or standard spacing).
* **NavComponent.vue (`.navbar`, `.logo`)**:
  * Uses hardcoded `padding: 0.75rem 1.5rem` (should be `var(--space-3) var(--space-6)`).
  * Uses hardcoded `gap: 0.6rem` (should be `var(--space-2)` or `var(--space-2.5)`).

### 1.3 Hardcoded Border Radii
* **App.vue (`.notice-dismiss`)**: Uses hardcoded `border-radius: 999px` (should be `var(--radius-pill)`).
* **ExamStatusFilter.vue (`.filter-pill`)**: Uses hardcoded `border-radius: 20px` (should be `var(--radius-pill)`).
* **NavComponent.vue (`.btn-settings`)**: Uses hardcoded `border-radius: 5px` (should be `var(--radius-md)`).
* **DropdownSelect.vue (`.dropdown-trigger`)**: Uses hardcoded `border-radius: 5px` (should be `var(--radius-md)`).
* **ExamDetailView.vue (`.status-pill`)**: Uses hardcoded `border-radius: 100px` (should be `var(--radius-pill)`).

### 1.4 Invalid CSS Custom Properties (Bugs)
* **ExpandedSentinelOverlay.vue (`.overlay-close`)**: Uses `color: var(--color)` which is undefined. Should be `color: var(--text-secondary)`.

### 1.5 Component Utility / Theming Issues
* **DropdownSelect.vue (`.dropdown-trigger`)**: Uses hardcoded white border/text and transparent/white hovers which are navbar-specific, rendering this component non-generic. We should theme it properly using CSS variables so that it's generic and reusable.

---

## 2. Implementation Plan

We will perform in-place replacements using standard token variables:
* Spacing Scale:
  * `4px` -> `var(--space-1)` (or `0.25rem`)
  * `8px` -> `var(--space-2)` (or `0.5rem`)
  * `12px` -> `var(--space-3)` (or `0.75rem`)
  * `16px` -> `var(--space-4)` (or `1rem`)
  * `20px` -> `var(--space-5)` (or `1.25rem`)
  * `24px` -> `var(--space-6)` (or `1.5rem`)
  * `32px` -> `var(--space-8)` (or `2rem`)
  * `40px` -> `var(--space-10)` (or `2.5rem`)
* Border Radii:
  * `5px` / `6px` -> `var(--radius-md)`
  * `8px` -> `var(--radius-lg)`
  * `12px` -> `var(--radius-xl)`
  * `20px` / `100px` / `999px` -> `var(--radius-pill)`
