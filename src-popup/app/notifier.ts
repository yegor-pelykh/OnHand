type Listener = () => void;

export class Notifier {
  private readonly _listeners: Listener[] = [];

  public addListener(listener: Listener): () => void {
    this._listeners.push(listener);
    return () => this.removeListener(listener);
  }

  public removeListener(listener: Listener): void {
    const idx: number = this._listeners.indexOf(listener);
    if (idx >= 0) {
      this._listeners.splice(idx, 1);
    }
  }

  public removeAllListeners(): void {
    this._listeners.splice(0, this._listeners.length);
  }

  public emit(): void {
    for (const listener of this._listeners) {
      listener();
    }
  }
}
