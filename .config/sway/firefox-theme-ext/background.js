const NIGHT_THEME = {
  colors: {
    frame:                 '#1c1b16',
    tab_background_text:   '#f2f1e5',
    toolbar:               '#1c1b16',
    toolbar_text:          '#f2f1e5',
    toolbar_field:         '#2e2d26',
    toolbar_field_text:    '#f2f1e5',
    popup:                 '#2e2d26',
    popup_text:            '#f2f1e5',
    tab_selected:          '#2e2d26',
    ntp_background:        '#1c1b16',
    ntp_text:              '#f2f1e5',
  }
};

const DAY_THEME = {
  colors: {
    frame:                 '#f2f1e5',
    tab_background_text:   '#000000',
    toolbar:               '#f2f1e5',
    toolbar_text:          '#000000',
    toolbar_field:         '#deddd1',
    toolbar_field_text:    '#000000',
    popup:                 '#deddd1',
    popup_text:            '#000000',
    tab_selected:          '#deddd1',
    ntp_background:        '#f2f1e5',
    ntp_text:              '#000000',
  }
};

function applyTheme(theme) {
  if (theme === 'dark') {
    browser.theme.update(NIGHT_THEME);
    browser.browserSettings.overrideContentColorScheme.set({ value: 'dark' });
  } else {
    browser.theme.update(DAY_THEME);
    browser.browserSettings.overrideContentColorScheme.set({ value: 'light' });
  }
}

function connect() {
  const port = browser.runtime.connectNative('theme_switcher');

  port.onMessage.addListener((msg) => {
    if (msg.theme) applyTheme(msg.theme);
  });

  port.onDisconnect.addListener(() => {
    setTimeout(connect, 3000);
  });
}

connect();
