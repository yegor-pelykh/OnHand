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

const connectedPorts = new Set<chrome.runtime.Port>();
const awaitingMessages: Map<string, MessageConfirmation> = new Map<string, MessageConfirmation>();
const messageHandlers = new Map<string, MessageHandler>([]);

function genUUID(): string {
    const s4 = () => Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
    return `${s4()}${s4()}-${s4()}-${s4()}-${s4()}-${s4()}${s4()}${s4()}`;
}

chrome.runtime.onConnect.addListener((port) => {
    connectedPorts.add(port);
    port.onDisconnect.addListener((port) => {
        connectedPorts.delete(port);
    });
    port.onMessage.addListener((message: Message, port) => {
        if ('uuid' in message && 'type' in message && 'data' in message) {
            const { uuid, type, data, error } = message;
            const confirmation = awaitingMessages.get(uuid);
            if (confirmation != null) {
                if (error != null) {
                    confirmation.reject(error);
                } else {
                    confirmation.resolve(data);
                }
                awaitingMessages.delete(uuid);
            } else {
                const handler = messageHandlers.get(type);
                if (handler != null) {
                    handler(port, data, error).then((responseData) => {
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
    });
});

async function sendMessage(port: chrome.runtime.Port, type: string, data: any, error?: string): Promise<any> {
    const uuid = genUUID();
    const promise = new Promise<any>((resolve, reject) => {
        awaitingMessages.set(uuid, <MessageConfirmation>{
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

async function broadcastMessage(type: string, data: any, error?: string): Promise<PromiseSettledResult<Object>[]> {
    const promises = Array.from(connectedPorts.values()).map(p => sendMessage(p, type, data, error));
    return await Promise.allSettled(promises);
}