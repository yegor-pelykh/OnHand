export class IconData {
  constructor(
    public contentType: string,
    public bytes: Uint8Array,
    public width: number = 0,
    public height: number = 0,
  ) {}
}
