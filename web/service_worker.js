"use strict";
const connectedPorts = new Set();
const awaitingMessages = new Map();
const messageHandlers = new Map([]);
function genUUID() {
    const s4 = () => Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
    return `${s4()}${s4()}-${s4()}-${s4()}-${s4()}-${s4()}${s4()}${s4()}`;
}
chrome.runtime.onConnect.addListener((port) => {
    connectedPorts.add(port);
    port.onDisconnect.addListener((port) => {
        connectedPorts.delete(port);
    });
    port.onMessage.addListener((message, port) => {
        if ('uuid' in message && 'type' in message && 'data' in message) {
            const { uuid, type, data, error } = message;
            const confirmation = awaitingMessages.get(uuid);
            if (confirmation != null) {
                if (error != null) {
                    confirmation.reject(error);
                }
                else {
                    confirmation.resolve(data);
                }
                awaitingMessages.delete(uuid);
            }
            else {
                const handler = messageHandlers.get(type);
                if (handler != null) {
                    handler(port, data, error).then((responseData) => {
                        port.postMessage({
                            uuid: uuid,
                            type: type,
                            data: responseData,
                        });
                    }).catch((reason) => {
                        const strError = typeof reason === 'string' ? reason : JSON.stringify(reason);
                        port.postMessage({
                            uuid: uuid,
                            type: type,
                            error: strError,
                        });
                    });
                }
                else {
                    port.postMessage({
                        uuid: uuid,
                        type: type,
                        error: 'There is no handler for this message',
                    });
                }
            }
        }
    });
});
async function sendMessage(port, type, data, error) {
    const uuid = genUUID();
    const promise = new Promise((resolve, reject) => {
        awaitingMessages.set(uuid, {
            resolve: resolve,
            reject: reject,
        });
        port.postMessage({
            uuid: uuid,
            type: type,
            data: data,
            error: error,
        });
    });
    return promise;
}
async function broadcastMessage(type, data, error) {
    const promises = Array.from(connectedPorts.values()).map(p => sendMessage(p, type, data, error));
    return await Promise.allSettled(promises);
}
