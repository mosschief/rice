user_pref("xpinstall.signatures.required", false);
user_pref("widget.use-xdg-desktop-portal.color-scheme", 1);
// Required for chrome/userChrome.css to be read at all — without it Firefox
// silently ignores the whole chrome/ directory.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
