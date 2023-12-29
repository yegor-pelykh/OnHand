import { Injectable } from '@angular/core';

export type Message = {
  uuid: string;
  type: string;
  data?: string;
  error?: string;
};
export type MessageConfirmation = {
  resolve: (value: any) => void;
  reject: (reason?: any) => void;
};
export type MessageHandler = (
  port: chrome.runtime.Port,
  data: any,
  error: any,
) => Promise<any>;

@Injectable({
  providedIn: 'root',
})
export class CommunicationService {
  private awaitingMessages: Map<string, MessageConfirmation> = new Map<
    string,
    MessageConfirmation
  >();
  private messageHandlers: Map<string, MessageHandler> = new Map<
    string,
    MessageHandler
  >([]);
  private port?: chrome.runtime.Port;

  get connected(): boolean {
    return this.port != null;
  }

  private genUUID(): string {
    const s4 = () =>
      Math.floor((1 + Math.random()) * 0x10000)
        .toString(16)
        .substring(1);
    return `${s4()}${s4()}-${s4()}-${s4()}-${s4()}-${s4()}${s4()}${s4()}`;
  }

  private getUniquePortName() {
    return `popup-${this.genUUID()}`;
  }

  private messageListener(message: Message, port: chrome.runtime.Port): void {
    if ('uuid' in message && 'type' in message && 'data' in message) {
      const { uuid, type, data, error } = message;
      const dataObj = data != null ? JSON.parse(data) : undefined;
      const errorObj = error != null ? JSON.parse(error) : undefined;
      const confirmation = this.awaitingMessages.get(uuid);
      if (confirmation != null) {
        if (errorObj != null) {
          confirmation.reject(errorObj);
        } else {
          confirmation.resolve(dataObj);
        }
        this.awaitingMessages.delete(uuid);
      } else {
        const response = <Message>{
          uuid: uuid,
          type: type,
        };
        const handler = this.messageHandlers.get(type);
        if (handler != null) {
          handler
            .call(this, port, dataObj, errorObj)
            .then((responseData) => {
              if (responseData != null) {
                response.data = JSON.stringify(responseData);
              }
              port.postMessage(response);
            })
            .catch((reason) => {
              if (reason != null) {
                response.error = JSON.stringify(reason);
              }
              port.postMessage(response);
            });
        } else {
          response.error = JSON.stringify(
            'There is no handler for this message',
          );
          port.postMessage(response);
        }
      }
    }
  }

  connect(): void {
    this.disconnect();
    this.port = chrome.runtime.connect({
      name: this.getUniquePortName(),
    });
    this.port.onMessage.addListener((message: any, port: chrome.runtime.Port) =>
      this.messageListener(message, port),
    );
  }

  disconnect() {
    if (this.port != null) {
      this.port.disconnect();
      this.port = undefined;
    }
  }

  async sendMessage(type: string, data: any, error?: string): Promise<any> {
    const uuid = this.genUUID();
    const promise = new Promise<any>((resolve, reject) => {
      if (this.port != null) {
        this.awaitingMessages.set(uuid, <MessageConfirmation>{
          resolve: resolve,
          reject: reject,
        });
        const msg = <Message>{
          uuid: uuid,
          type: type,
        };
        if (data != null) {
          msg.data = JSON.stringify(data);
        }
        if (error != null) {
          msg.error = JSON.stringify(error);
        }
        this.port.postMessage(msg);
      } else {
        this.awaitingMessages.delete(uuid);
        reject('The port is not connected.');
      }
    });
    return promise;
  }
}
