import { Injectable } from '@angular/core';

export type Message = {
  uuid: string,
  type: string,
  data: any,
  error?: string,
}
export type MessageConfirmation = {
  resolve: ((value: any) => void),
  reject: ((reason?: any) => void),
}
export type MessageHandler = (port: chrome.runtime.Port, data: any, error?: string) => Promise<any>;

@Injectable({
  providedIn: 'root'
})
export class CommunicationService {
  private awaitingMessages: Map<string, MessageConfirmation> = new Map<string, MessageConfirmation>();
  private messageHandlers: Map<string, MessageHandler> = new Map<string, MessageHandler>([]);
  private port?: chrome.runtime.Port;

  get connected(): boolean {
    return this.port != null;
  }

  private genUUID(): string {
    const s4 = () => Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
    return `${s4()}${s4()}-${s4()}-${s4()}-${s4()}-${s4()}${s4()}${s4()}`;
  }

  private getUniquePortName() {
    return `popup-${this.genUUID()}`;
  }

  private messageListener(message: any, port: chrome.runtime.Port): void {
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

  connect(): void {
    this.disconnect();
    this.port = chrome.runtime.connect({
      name: this.getUniquePortName(),
    });
    this.port.onMessage.addListener((message: any, port: chrome.runtime.Port) => this.messageListener(message, port));
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
        this.port.postMessage(<Message>{
          uuid: uuid,
          type: type,
          data: data,
          error: error,
        });
      } else {
        this.awaitingMessages.delete(uuid);
        reject('The port is not connected.');
      }
    });
    return promise;
  }

}
