## ADDED Requirements

### Requirement: Consistent visual language across the authenticated app
Every authenticated page — the admin area and the self-service profile page alike — SHALL
present a single, consistent visual language — colors, typography, and interactive components
(buttons, inputs, badges, cards, modals) and a shared navigation shell — rather than each page
defining its own styling.

#### Scenario: Shared component styling
- **WHEN** a badge, button, or form input is rendered on any authenticated page (the User list,
  an import's history, a modal opened from either, or the profile page)
- **THEN** it uses the same visual style (color, shape, spacing) as its equivalent on every other
  authenticated page

#### Scenario: Navigation reflects what a User can access
- **WHEN** the navigation shell is shown to a signed-in User
- **THEN** it always offers their own profile and the ability to sign out, and only offers the
  admin-only sections (Users, Imports) when that User is an admin

### Requirement: Responsive layout
The authenticated app SHALL remain fully usable across desktop, tablet, and mobile viewport
widths, without requiring horizontal scrolling to read primary content or losing access to
navigation.

#### Scenario: Desktop and tablet
- **WHEN** an authenticated page is viewed at a tablet width or wider
- **THEN** the navigation sidebar is fixed and visible alongside the page content

#### Scenario: Mobile navigation
- **WHEN** an authenticated page is viewed below the tablet width
- **THEN** the navigation sidebar is hidden by default and opens as a drawer from a menu control
  in the top bar, without permanently occupying page width

#### Scenario: Mobile list rendering
- **WHEN** a list with many columns (the User list, or the import history) is viewed below the
  tablet width
- **THEN** each row renders as a stacked card of its fields instead of a wide table, so no
  column is clipped and no horizontal scroll is needed to read a row

#### Scenario: Mobile modal sizing
- **WHEN** a modal (create/edit/delete User, an import's progress, or the profile page's own
  delete-account confirmation) is opened below the tablet width
- **THEN** it occupies nearly the full viewport width instead of a fixed dialog size that could
  overflow the screen

#### Scenario: Content fills the available screen
- **WHEN** an authenticated page is viewed at any viewport size
- **THEN** its layout fills the actual browser viewport rather than being constrained to a
  smaller area with unused space around it

### Requirement: Destructive actions require confirmation
An action that permanently removes data SHALL require an explicit confirmation step in a dialog
before it takes effect, whether performed by an admin on another User or by a User on their own
account.

#### Scenario: Confirming a destructive action
- **WHEN** a signed-in User triggers a destructive action (such as an admin deleting a User, or
  a User deleting their own account)
- **THEN** a confirmation dialog appears describing what will be removed, and the action only
  proceeds if they explicitly confirm it

#### Scenario: Cancelling a destructive action
- **WHEN** a signed-in User dismisses or cancels the confirmation dialog
- **THEN** nothing is removed and they return to where they were
