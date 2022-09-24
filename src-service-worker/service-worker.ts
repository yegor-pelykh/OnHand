type Message = {
    uuid: string,
    type: string,
    data: any,
    error?: string,
}
type MessageConfirmation = {
    resolve: ((value: any) => void),
    reject: ((reason?: any) => void),
}
type MessageHandler = (port: chrome.runtime.Port, data: any, error?: string) => Promise<any>;

abstract class Helpers {
    static genUUID(): string {
        const s4 = () => Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
        return `${s4()}${s4()}-${s4()}-${s4()}-${s4()}-${s4()}${s4()}${s4()}`;
    }
}

abstract class ConnectionManager {
    private static connectedPorts: Set<chrome.runtime.Port> = new Set<chrome.runtime.Port>();
    private static awaitingMessages: Map<string, MessageConfirmation> = new Map<string, MessageConfirmation>();
    private static messageHandlers: Map<string, MessageHandler> = new Map<string, MessageHandler>([
        [ 'get-data', this.handlerGetData ],
    ]);

    private static getPortType(portName: string) {
        const nameLowerCase = portName.toLowerCase();
        if (nameLowerCase.startsWith('popup')) {
            return 'popup';
        }
        return 'content';
    }

    private static messageListener(message: Message, port: chrome.runtime.Port): void {
        if ('uuid' in message && 'type' in message && 'data' in message) {
            const { uuid, type, data, error } = message;
            const confirmation = this.awaitingMessages.get(uuid);
            if (confirmation != null) {
                if (error != null) {
                    confirmation.reject(error);
                } else {
                    confirmation.resolve(data);
                }
                this.awaitingMessages.delete(uuid);
            } else {
                const handler = this.messageHandlers.get(type);
                if (handler != null) {
                    handler.call(this, port, data, error).then((responseData) => {
                        port.postMessage(<Message>{
                            uuid: uuid,
                            type: type,
                            data: responseData,
                        });
                    }).catch((reason) => {
                        const strError = typeof reason === 'string' ? reason : JSON.stringify(reason);
                        port.postMessage(<Message>{
                            uuid: uuid,
                            type: type,
                            error: strError,
                        });
                    });
                } else {
                    port.postMessage(<Message>{
                        uuid: uuid,
                        type: type,
                        error: 'There is no handler for this message',
                    });
                }
            }
        }
    }

    private static handlePortDisconnection(port: chrome.runtime.Port): void {
        this.connectedPorts.delete(port);
    }

    static handlePortConnection(port: chrome.runtime.Port): void {
        this.connectedPorts.add(port);
        port.onDisconnect.addListener((port) => this.handlePortDisconnection(port));
        port.onMessage.addListener((message, port) => this.messageListener(message, port));
    }

    static async sendMessage(port: chrome.runtime.Port, type: string, data: any, error?: string): Promise<any> {
        const uuid = Helpers.genUUID();
        const promise = new Promise<any>((resolve, reject) => {
            this.awaitingMessages.set(uuid, <MessageConfirmation>{
                resolve: resolve,
                reject: reject,
            });
            port.postMessage(<Message>{
                uuid: uuid,
                type: type,
                data: data,
                error: error,
            });
        });
        return promise;
    }

    static async broadcastMessage(type: string, data: any, error?: string): Promise<PromiseSettledResult<Object>[]> {
        const promises = Array.from(this.connectedPorts.values()).map(p => this.sendMessage(p, type, data, error));
        return await Promise.allSettled(promises);
    }

    static async handlerGetData(port: chrome.runtime.Port, data: any, error?: string) {
        const contentPort = Array.from(this.connectedPorts).find(p => this.getPortType(p.name) === "content");
        if (contentPort != null) {
            return await this.sendMessage(contentPort, 'get-data', null);
        } else {
            return null;
        }
    }

}

abstract class ActionHandler {
    private static allowedSchemes: string[] = [
        'https',
        'http',
    ];

    static setV2ActionRules() {
        if (chrome.pageAction == null) {
            return;
        }
        const applyPageActionVisibility = (tab: chrome.tabs.Tab) => {
            const isUrlAllowed = (url: string) => {
                return this.allowedSchemes.some((scheme: string) => {
                    return url.toLowerCase().startsWith(`${scheme.toLowerCase()}:`);
                });
            };
            if (tab.id != null && tab.url != null) {
                if (isUrlAllowed(tab.url)) {
                    chrome.pageAction.show(tab.id);
                } else {
                    chrome.pageAction.hide(tab.id);
                }
            }
        }
        chrome.tabs.query({}, (tabs) => {
            for (const tab of tabs) {
                applyPageActionVisibility(tab);
            }
        });
        chrome.tabs.onUpdated.addListener((_tabId, _changeInfo, tab) => {
            applyPageActionVisibility(tab);
        });
    }

    static setV3ActionRules() {
        if (chrome.action == null || chrome.declarativeContent == null) {
            return;
        }
        chrome.action.disable();
        chrome.declarativeContent.onPageChanged.removeRules(undefined, () => {
            const rules = [
                {
                    conditions: [
                        new chrome.declarativeContent.PageStateMatcher({
                            pageUrl: {
                                schemes: this.allowedSchemes
                            },
                        })
                    ],
                    actions: [
                        new chrome.declarativeContent.ShowAction(),
                    ],
                },
            ];
            chrome.declarativeContent.onPageChanged.addRules(rules);
        });
    }
}

abstract class LifecycleHandler {
    private static onInstalledListener() {
        ActionHandler.setV2ActionRules();
        ActionHandler.setV3ActionRules();
    }

    private static onPortConnectedListener(port: chrome.runtime.Port) {
        ConnectionManager.handlePortConnection(port);
    }

    static init(): void {
        chrome.runtime.onInstalled.addListener(() => this.onInstalledListener());
        chrome.runtime.onConnect.addListener((port) => this.onPortConnectedListener(port));
    }
}

LifecycleHandler.init();