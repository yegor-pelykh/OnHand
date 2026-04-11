export interface IconData {
  readonly url: string;
  readonly width?: number;
  readonly height?: number;
}

export interface Metadata {
  readonly title?: string;
  readonly icon?: IconData;
}
