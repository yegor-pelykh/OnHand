class ActionHandler {
  private static readonly allowedSchemes: string[] = ['https', 'http', 'ftp'].map(s => s.toLowerCase());

  private static _legacyPageActionUpdateListener:
    | ((tabId: number, changeInfo: chrome.tabs.OnUpdatedInfo, tab: chrome.tabs.Tab) => void)
    | null = null;

  public static async setActionRules(): Promise<void> {
    if (chrome.action != null && chrome.declarativeContent != null) {
      await this._setDeclarativeActionRules();
    } else if (chrome.pageAction != null) {
      this._setLegacyPageActionRules();
    } else {
      // eslint-disable-next-line no-console
      console.warn(
        'No suitable browser action API found (chrome.action/declarativeContent or chrome.pageAction). Extension functionality might be limited.'
      );
    }
  }

  private static async _setDeclarativeActionRules(): Promise<void> {
    if (chrome.action === undefined || chrome.declarativeContent === undefined) {
      return;
    }
    await chrome.action.disable();
    chrome.declarativeContent.onPageChanged.removeRules(undefined, () => {
      const rules = [
        {
          conditions: [
            new chrome.declarativeContent.PageStateMatcher({
              pageUrl: {
                schemes: this.allowedSchemes,
              },
            }),
          ],
          actions: [new chrome.declarativeContent.ShowAction()],
        },
      ];
      chrome.declarativeContent.onPageChanged.addRules(rules);
    });
  }

  private static _setLegacyPageActionRules(): void {
    if (chrome.pageAction == null) {
      return;
    }
    const isUrlAllowed = (url: string): boolean =>
      this.allowedSchemes.some((scheme: string) => url.toLowerCase().startsWith(`${scheme}:`));
    const applyPageActionVisibility = (tab: chrome.tabs.Tab): void => {
      if (tab.id != null && tab.url != null) {
        if (isUrlAllowed(tab.url)) {
          chrome.pageAction.show(tab.id);
        } else {
          chrome.pageAction.hide(tab.id);
        }
      }
    };
    if (ActionHandler._legacyPageActionUpdateListener) {
      chrome.tabs.onUpdated.removeListener(ActionHandler._legacyPageActionUpdateListener);
    }
    chrome.tabs.query({}, tabs => {
      for (const tab of tabs) {
        applyPageActionVisibility(tab);
      }
    });
    ActionHandler._legacyPageActionUpdateListener = (_tabId, _changeInfo, tab): void => {
      applyPageActionVisibility(tab);
    };
    chrome.tabs.onUpdated.addListener(ActionHandler._legacyPageActionUpdateListener);
  }
}

class LifecycleHandler {
  public static init(): void {
    chrome.runtime.onInstalled.addListener(() => void this.setRules());
    chrome.runtime.onStartup.addListener(() => void this.setRules());
  }

  private static async setRules(): Promise<void> {
    await ActionHandler.setActionRules();
  }
}

LifecycleHandler.init();
