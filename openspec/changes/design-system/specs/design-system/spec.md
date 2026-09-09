## ADDED Requirements

### Requirement: Consistent visual language across the admin area
The admin area SHALL present a single, consistent visual language — colors, typography, and
interactive components (buttons, inputs, badges, cards, modals) — shared across every admin
page, rather than each page defining its own styling.

#### Scenario: Shared component styling
- **WHEN** a badge, button, or form input is rendered on any admin page (the User list, an
  import's history, or a modal opened from either)
- **THEN** it uses the same visual style (color, shape, spacing) as its equivalent on every
  other admin page

### Requirement: Responsive layout
The admin area SHALL remain fully usable across desktop, tablet, and mobile viewport widths,
without requiring horizontal scrolling to read primary content or losing access to navigation.

#### Scenario: Desktop and tablet
- **WHEN** the admin area is viewed at a tablet width or wider
- **THEN** the navigation sidebar is fixed and visible alongside the page content

#### Scenario: Mobile navigation
- **WHEN** the admin area is viewed below the tablet width
- **THEN** the navigation sidebar is hidden by default and opens as a drawer from a menu control
  in the top bar, without permanently occupying page width

#### Scenario: Mobile list rendering
- **WHEN** a list with many columns (the User list, or the import history) is viewed below the
  tablet width
- **THEN** each row renders as a stacked card of its fields instead of a wide table, so no
  column is clipped and no horizontal scroll is needed to read a row

#### Scenario: Mobile modal sizing
- **WHEN** a modal (create/edit/delete User, or an import's progress) is opened below the
  tablet width
- **THEN** it occupies nearly the full viewport width instead of a fixed dialog size that could
  overflow the screen

### Requirement: Destructive actions require confirmation
An action that permanently removes data SHALL require an explicit confirmation step in a dialog
before it takes effect.

#### Scenario: Confirming a destructive action
- **WHEN** an admin triggers a destructive action (such as deleting a User)
- **THEN** a confirmation dialog appears describing what will be removed, and the action only
  proceeds if the admin explicitly confirms it

#### Scenario: Cancelling a destructive action
- **WHEN** an admin dismisses or cancels the confirmation dialog
- **THEN** nothing is removed and the admin returns to where they were
